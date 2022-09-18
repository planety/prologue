# Deploying Prologue with nginx and docker
This is an example of how you can deploy a prologue web-application that was compiled under Linux.
.
## Base Images

We will look at 2 base images as starting points:

2. [bitnami/mindeb](https://hub.docker.com/r/bitnami/minideb)
3. [alpine](https://hub.docker.com/_/alpine)

The process is similar for both, but does contain differences, particularly in the dockerfile and commands needed to compile your project.

This guide assumes that:

1. You have a server
2. You can ssh into your server
3. You can copy files to your server via e.g. scp
4. You have set up your server with a domain name

## Compile your binary
Compiling your binary differs between alpine and other linux images.
This is because unlike most other linux distributions, alpine does not use the `gnu c library` (glibc) to link its binaries against.
Alpine uses `musl`, which is much more minimalistic.

Because `musl` and `glibc` are different, compiling your application to link with them also differs.

### On bitnami/mindeb
bitnami/minideb is basically a debian image, reduced to the minimum.

Since it is based on debian, it uses `gnu c library` (glibc), which is the main advantage of this image. 

Since the majority of Linux systems use `glibc`, compiling on any Linux distro will give you a binary that is dynamically linked against your `glibc` version and thus is likely to work in the image.
If you have to ask whether your distro is using `glibc`, you are using `glibc`.

You can compile your project like this:
```sh
nim c \
--forceBuild:on \
--opt:speed \
--define:release \
--threads:on \
--mm:orc \
--deepcopy:on \
--define:lto \
--define:ssl \
--hints:off \
--outdir:"." \
<PATH_TO_YOUR_MAIN_PROJECT_FILE>.nim
```

If you want to avoid re-typing all the flags, you can define them in a [nimble task](https://github.com/nim-lang/nimble#nimble-tasks) that you can trigger instead!
Just add the following to your `<YOUR_PROJECT>.nimble` file (run [`nimble init`](https://github.com/nim-lang/nimble#nimble-init) if you don't have one):

```txt
task release, "Build a production release":
  --verbose
  --forceBuild:on
  --opt:speed
  --define:release
  --threads:on
  --mm:orc
  --deepcopy:on
  --define:lto
  --define:ssl # If you use smtp clients
  --hints:off
  --outdir:"."
  setCommand "c", "src/<YOUR_MAIN_FILE>.nim"
```

This allows you to run `nimble release` in your project to compile it with the specified flags!

### On alpine
Alpine is among the smallest image out there. 
At barely 5.53MB, any image you base on it is unlikely to get large. 
This doesn't have effects on your application's performance, but does speed deployment as the image uploads faster to your server.

Since Alpine uses `musl`, compiling has some extra steps.
For simplicities' sake, we will be linking to musl dynamically.

#### Install musl

1. [download](https://www.musl-libc.org/download.html) the tar file
2. Unpack the tar file somewhere
3. Run `bash configure` in the unpacked directory. WARNING: Make sure that you do NOT install musl with `--prefix` being  `/usr/local`, as that may adversely affect your system. Use somewhere else where it is unlikely to override files, e.g. `/usr/local/musl`. This path will further be referred to as `<MUSL_INSTALL_PATH>`
4. Run `make && make install` in the unpacked directory
5. Add `<MUSL_INSTALL_PATH>` to your PATH environment variable
6. Validate whether you set everything up correctly by opening a new terminal and seeing whether you have access to the `musl-gcc` binary

#### Compiling your dynamically linked musl binary
Like before, you can write a compile command. 
This time though, we need to tell the compiler to use `musl-gcc` instead of `gcc` to dynamically link with `musl`.
We similarly want to replace the linker with `musl-gcc`.
We can use the flags `--gcc.exe:"musl-gcc"` and `--gcc.linkerexe:"musl-gcc"` to get a compile command:

```sh
nim c \
--gcc.exe:"musl-gcc" \
--gcc.linkerexe:"musl-gcc" \
--forceBuild:on \
--opt:speed \
--define:release \
--threads:on \
--mm:orc \
--deepcopy:on \
--define:lto \
--define:ssl \
--hints:off \
--outdir:"." \
<PATH_TO_YOUR_MAIN_PROJECT_FILE>.nim
```

Instead of a bash script we can also just set up a nimble task instead:
```txt
task alpine, "Build an alpine release":
  --verbose
  --gcc.exe:"musl-gcc"
  --gcc.linkerexe:"musl-gcc"
  --forceBuild:on
  --opt:speed
  --define:release
  --threads:on
  --mm:orc
  --deepcopy:on
  --define:lto
  --define:ssl
  --hints:off
  --outdir:"."
  setCommand "c", "src/nimstoryfont.nim"
```

## Prepare buildFiles

1. Set up the server to have SSL certificates with certbot to get `fullchain.pem` and `privkey.pem` files
2. Write an `nginx.conf` file to configure nginx
3. Write a bash file `dockerStartupScript.sh` to run inside the docker container when starting it.
4. Write a `settings.json` file for prologue

We will store these files in a directory called `buildFiles` and include them in our docker image(s) later.

### Set up your server to have SSL certificates with certbot
There are many great resources on how you can get free SSL certificates.
We recommend using [certbot](https://certbot.eff.org/instructions). 
Follow the instructions on their website to set up your certificates.

After the initial setup, you should automate the renewal of those certificates.
Renewal is easily done with [`sudo certbot renew`](https://eff-certbot.readthedocs.io/en/stable/using.html#renewing-certificates), but requires you to shut down the webserver first and boot it up after renewal again.
We recommend setting up a cronjob to regularly run the `certbot renew` command.
User certbot's "pre-hook" and "post-hook" to shut down/starts up your container/docker-compose before and after the actual renewal happens.

```txt
certbot renew --pre-hook "docker container stop <YOUR_CONTAINER_NAME>" --post-hook "docker container start <YOUR_CONTAINER_NAME>"
```

### Provide an `nginx.conf` config file
Nginx requires a config file, `nginx.conf` to define what files to serve and how to forward requests to the prologue application.

Here we'll set nginx up to use SSL with the SSL certificates received from the previous step.
Further, to make nginx forward requests to our prologue backend, we use its "[proxy_pass](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass)" directive.

Note that all directories in the config file are directories within the *docker* container, not your actual server.

See below an example of a small `nginx.conf` file:
```txt
#user http;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    types_hash_max_size 4096;

    sendfile        on;

    keepalive_timeout  30;
    proxy_send_timeout 30;

    # Enforces HTTPS by redirecting users with HTTP requests to the HTTPS URL
    server {
        listen 80;
        listen [::]:80;

        server_name <SERVER_NAME>;

        return 301 https://$server_name$request_uri;
    }

    server {
        server_name <SERVER_NAME>;
        autoindex off;

        listen 443 ssl http2;
        listen [::]:443 ssl http2;       
        
        root /media;

        # Passes requests on to the prologue application server
        location /server {
            rewrite ^/server/(.*) /$1  break; #Removes "/server" from the url for the application-server
            
            proxy_pass http://localhost:8080; #Hands request over to localhost:8080 where the application server is listening
            proxy_set_header Host $host;
            proxy_send_timeout 600;
            proxy_set_header X-Real_IP $remote_addr;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        ssl_certificate /cert/live/<SERVER_NAME>/fullchain.pem;
        ssl_certificate_key /cert/live/<SERVER_NAME>/privkey.pem;
    }
}
```

Note that the file assumes there will be a `fullchain.pem` and `privkey.pem`, which you currently have on your server (e.g. `/etc/letsencrypt/live`). 
We will make these certificates accessible by creating the `/cert/live` directories inside the docker image and mounting the certificate directory to that folder (e.g. when creating a container via [docker volumes](https://docs.docker.com/storage/volumes/)).

For now store your `nginx.conf` file in your `./buildFiles` directory.

### Provide a `settings.json` config file for prologue
In order for prologue to function correctly, we will provide a simple settings file.

```json
    "prologue": {
        "address": "",
        "port": 8080,
        "debug": false,
        "reusePort": true,
        "appName": "<YOUR APP NAME>",
        "secretKey": "<YOUR SECRET KEY>",
        "bufSize": 409600
    },
    "name": "production",
```

Note that the port you specify here must be the same port used in the `proxy_pass` directive of `./buildFiles/nginx.conf`.

Put this `settings.json` in your `./buildFiles` directory. 

## Setting up docker
After completing the prior steps, we can now think how to deploy our application how we want to deploy our application and server.
We have 2 different applications to manage here: nginx and our prologue application. We can deploy these in 2 different ways:

- Prologue and Nginx in the same container (simpler)
- Prologue and Nginx in separate containers via docker-compose (Enables hosting multiple web-applications from the same server)

## A) Prologue and Nginx in the same container

When deploying prologue and nginx in the same container we need to start both applications on when starting the container.
To do so we can set up a `startupScript.sh` file that gets executed when the container gets started.
We will be using `openrc` to start and manage nginx.

```bash
#!/bin/sh
# This file contains all commands that shall be run on the docker container on startup
openrc boot # Enables running rc-service, which manages nginx
rc-service nginx start # Starts up nginx
/<YOUR_BINARY> # Starts your prologue application
```

Store your script file locally in `./buildFiles/startupScript.sh`.

### Write your dockerfile
After completing the prior steps, we can write a `dockerfile`.
It will contain the instructions to create a docker image, from which containers are made.

This process differs between `bitnami/minideb` and `alpine`, since `alpine` uses `apk` to install packages from the [alpine repositories](https://alpine.pkgs.org/?) while `bitnami/minideb` uses apt to install [debian packages](https://www.debian.org/distrib/packages). 
This means the installation commands and package names differ.

We will also set up various folders, in order to later use them as mounting points for [docker volumes](https://docs.docker.com/storage/volumes/) when creating containers from our images. 
This way you can access files inside the container (e.g. media files so that nginx can serve them, or an sqlite database) without loosing them when the container shuts down.

Store the dockerfile on your applications root directory.

#### On `bitnami/minideb`
To install packages without `apt`'s commandline prompts, this image ships a `install_packages` command.
Here an example `dockerfile`:
```txt
FROM bitnami/minideb

# Install dependencies
RUN apt update
RUN install_packages openrc openssl nginx
# RUN install_packages sqlite3 # in case you use an sqlite3 database

# Copy necessary files, the first paths are all relative to your current working directory
COPY ./<PATH_TO_YOUR_BINARY> .
COPY ./buildFiles/nginx.conf /etc/nginx/nginx.conf
COPY ./buildFiles/dockerStartScript.sh .
COPY ./buildFiles/settings.json /settings.json
RUN chmod 777 /settings.json

# Setup directories to add volumes to when creating the container
RUN mkdir -p /run/nginx
RUN mkdir -p /cert/live/<YOUR_SERVER_NAME>
RUN mkdir -p /cert/archive/<YOUR_SERVER_NAME>
RUN mkdir /media

#Startup command
RUN chmod +x /dockerStartScript.sh
CMD ["/dockerStartScript.sh"]
```

#### On `alpine`
Here an example dockerfile:
```txt
FROM alpine

# Install dependencies
RUN apk update
RUN apk add openrc nginx openssl bash
# RUN apk add sqlite-libs # in case you use an sqlite3 database

# Copy necessary files
COPY ./buildFiles/nginx.conf /etc/nginx/nginx.conf
COPY ./buildFiles/dockerStartScript.sh .
COPY ./buildFiles/settings.json /settings.json
RUN chmod 777 /settings.json

# Setup directories to add volumes to when creating the container
RUN mkdir -p /run/nginx
RUN mkdir -p /cert/live/<YOUR_SERVER_NAME>
RUN mkdir -p /cert/archive/<YOUR_SERVER_NAME>
RUN mkdir /media

#Startup command
RUN chmod +x /dockerStartScript.sh
CMD ["/dockerStartScript.sh"]
```

### Build the docker image
With the binary, buildFiles and dockerfile ready, you can create your image:

```sh
# Creates your image
sudo docker build -t <YOUR_IMAGE_NAME> .
# Stores your image in your current working directory in a file called "image.tar"
sudo docker save -o image.tar <YOUR_IMAGE_NAME>
```

Once created, move that image file to your server, e.g. through `scp`.

### Run the docker image on your server
After copying your `image.tar` file to the server, you can load it there with docker and run a container from it.
Besides starting the container, the commands needs to:

1. Open up the container's HTTP port to the internet (80)
2. Open up the container's HTTPS port to the internet (443)
3. Mount the volumes for certificates, media files etc.
4. (Optional) Open up a port to talk to your database (e.g. 5432 for Postgres)

Opening up the ports is done using `-p`, mounting the volumes with `-v`.
Note that in `-v`, the first path is the one *outside* your container. 
It specifies which folder on your server to mount. 
The second path is the one *inside* your container. 
It specifies which folder in your container the server folder gets mounted to.

You may want to write yourself a script that loads the file, stops and removes any previously running container and then creates a new one from the new image. 
Here an example:
```sh
#!/bin/sh
sudo docker load -i image.tar

sudo docker container stop <YOUR_CONTAINER_NAME>
sudo docker container rm <YOUR_CONTAINER_NAME>

sudo docker run -p 80:80 -p 443:443 \
-v /etc/letsencrypt/live/<SERVER_NAME>:/cert/live/<SERVER_NAME>:ro \
-v /etc/letsencrypt/archive/<SERVER_NAME>:/cert/archive/<SERVER_NAME>:ro \
-v <PATH_TO_MEDIA_FOLDER>/media:/media \
-v <PATH_TO_DIRECTORY_FOR_SERVER_LOGS>:/var/log/nginx \
--name <YOUR_IMAGE_NAME> <YOUR_CONTAINER_NAME>
```

Now you can run the command (or script), and your container will start up and be accessible via HTTP and HTTPS!

## B) Prologue and Nginx in separate containers via docker-compose
 
You can have your proxy (nginx) and your webserver (prologue) also in different images and thus different containers, that can communicate.
For this you need to set it up so they get started together, with the ports they need opened and volumes they need mounted etc. 
That's where you use [docker-compose](https://docs.docker.com/get-started/08_using_compose/).

First, add 2 directories to `./buildFiles` to separate the config files and dockerfiles of your proxy and your webserver:

- `./buildFiles/nginx`
  - Move the `nginx.conf` here
- `./buildFiles/prologue`
  - Move the `settings.json` here
  - Move your application binary here

Also, change your commands or nimble tasks for compiling to output into the `./buildFiles/prologue` directory.

### Write your `docker-compose.yml`
A docker compose file contains the same things you would write in a `docker run` command:
name of the container, the image to use, which volumes to mount, which ports to expose etc.

Here an example of such a `docker-compose.yml` file that you can keep in your projects main folder:
```txt
version: "3.4"
services:
  #Nginx Reverse Proxy
  proxy:
    image: <NGINX_IMAGE_NAME>
    ports:
     - "443:443"
     - "80:80"
    volumes:
      -/etc/letsencrypt/live/<SERVER_NAME>:/cert/live/<SERVER_NAME>
      -/etc/letsencrypt/archive/<SERVER_NAME>:/cert/archive/<SERVER_NAME>
      - <PATH_TO_MEDIA_FOLDER>/media:/media
      - <PATH_TO_DIRECTORY_FOR_SERVER_LOGS>:/var/log/nginx
    container_name: <NGINX_CONTAINER_NAME>
  
  #Prologue webserver that receives requests on port 8080
  prologue:
    image: <PROLOGUE_IMAGE_NAME>
    expose: 
      - "8080" # Annotation for readability to make it clear that this container should be talked to on port 8080
    volumes:
      - <PATH_TO_MEDIA_FOLDER>/media:/media
    container_name: <PROLOGUE_CONTAINER_NAME>
```

To run this docker compose file with `docker-compose up`, you will first need to build images with the names you specify up there.

This means you now need 2 dockerfiles that can build these images. 

### Write your nginx dockerfile
An example for a dockerfile of an alpine image with nginx:
```txt
FROM alpine

# Install dependencies
RUN apk update
RUN apk add nginx openssl --no-cache

# Copy necessary files
COPY ./nginx.conf /etc/nginx/nginx.conf #Filepath is relative to dockerfile

# Setup directories to add volumes to when creating the container
RUN mkdir -p /run/nginx
RUN mkdir -p /cert/live/<YOUR_SERVER_NAME>
RUN mkdir -p /cert/archive/<YOUR_SERVER_NAME>
RUN mkdir /media

# Command to start nginx in container
CMD ["nginx", "-g", "daemon off;"]
```

Since the container only contains nginx, we can use `CMD ["nginx", "-g", "daemon off;"]` instead of a bash script to start it. 

Put the dockerfile in `./buildFiles/nginx`

We could have used the [official nginx alpine image](https://hub.docker.com/_/nginx/) instead of vanilla alpine, but decided against it.
Main reason being that the image appears to be binary-incompatible with the nginx-mods that can be installed via `apk`.
Other than that, the official nginx image can be used just as well.

### Write your prologue dockerfile
An example for a dockerfile of an alpine image with our prologue application:
```txt
FROM alpine

# Install dependencies
RUN apk update
RUN apk add openssl
# RUN apk add sqlite-libs # in case you use an sqlite3 database

# Copy necessary files
COPY ./<YOUR_APPLICATION_BINARY> .    #Filepath is relative to dockerfile
COPY ./settings.json /settings.json   #Filepath is relative to dockerfile

# Setup necessary directories
RUN mkdir /media

#Startup command
CMD ["/<YOUR_APPLICATION_BINARY>"]
```
Since the container only contains our application, we can just start it via `CMD ["/<YOUR_APPLICATION_BINARY>"]`.

Put the dockerfile in `./buildFiles/prologue`.

### Build the docker images
With the dockerfiles ready, we can create the images via the following commands from the applications root directory:

```sh
#!/bin/sh
# Creates your image
sudo docker build --file ./buildFiles/nginx/dockerfile --tag <NGINX_IMAGE_NAME> ./buildFiles/nginx
sudo docker build --file ./buildFiles/nimstoryfont/dockerfile --tag <PROLOGUE_IMAGE_NAME> ./buildFiles/nimstoryfont

# Stores your images in your current working directory
sudo docker save -o nginx-image.tar <NGINX_IMAGE_NAME> 
sudo docker save -o prologue-image.tar <PROLOGUE_IMAGE_NAME>
```

Once created, move that image file to your server, e.g. via `scp`.

### Run the docker image on your server
After copying your `docker-compose.yml`, the `nginx-image.tar` and the `prologue-image.tar` to your server, you can deploy your application.

Simply load the images into docker and run `docker-compose up` (or `docker-compose restart`).
There is no need to specify volumes or ports, as that is already in the `docker-compose.yml`.

You may want to write yourself a small script that loads the images and restarts:
```sh
#!/bin/sh
sudo docker load -i <NGINX_IMAGE_NAME>.tar
sudo docker load -i <PROLOGUE_IMAGE_NAME>.tar

sudo docker-compose restart
```

Run the command and your containers will start up and be accessible via HTTP and HTTPS!

# Known issues
## Compile your binary (under `bitnami/minideb` - `error "/lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_<X.XX>' not found"`
You will run into this issue if your local `glibc` version is more up-to-date than the one `bitnami/minideb` has access to.
This is the case because during compilation your binary is dynamically linked with your local `glibc` version.
That means in order to run, it expects the environment that executes it to have *at least* that same glibc version.

To fix this, you need to link your binary to an older glibc version when compiling, even though your own version is newer.
[Doing so is not straightforward.](https://stackoverflow.com/questions/2856438/how-can-i-link-to-a-specific-glibc-version)

### Solution 1: Using zig
The simplest way is installing the [compiler og the zig programming language](https://ziglang.org/download/), as it contains a Clang compiler, which you can tell which glibc version to use.

The steps go as follows:

- Install zig
- Write a bashscript called `zigcc`

```sh
#!/bin/sh
zig cc $@
```

- Move `zigcc` to somewhere on your path, e.g. `/usr/local/bin`.
This is required since the nim compiler does not tolerate spaces in commands that call compilers.
- Write yourself a bashscript with a command to compile your project. 
This can't be done via nimble tasks since the syntax is not allowed within nimble tasks.
Replace the "X.XX" with the glibc version that you want as well as the other placeholders.

```sh
#!/bin/sh
# Call this file projectCompile.sh
nim c \
--cc:clang \
--clang.exe="zigcc" \
--clang.linkerexe="zigcc" \
--passC:"-target x86_64-linux-gnu.X.XX -fno-sanitize=undefined" \
--passL:"-target x86_64-linux-gnu.X.XX -fno-sanitize=undefined" \
--forceBuild:on \
--opt:speed \
--deepcopy:on \
--mm:orc \
--define:release \
--define:lto \
--define:ssl \
--outdir:"." \
src/<YOUR_MAIN_FILE>.nim
```

- Run projectCompile.sh

### Solution 2: Create a compilation environment
Instead of using zig, you can set up a second docker container that contains the glibc version you want, gcc, nim, nimble and the C-libs you require. 
You can then mount your project-folder via [docker volume](https://docs.docker.com/storage/volumes/) in the container and compile as normal.
Then, you can just compile your binary within the container as usual, your normal compilation command.
