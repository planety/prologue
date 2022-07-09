# Deploying Prologue with nginx and docker
This is an example of how you can deploy a prologue web-application that was compiled under Linux.
In this example we will use nginx as our reverse proxy, and bundle our application together with nginx in a single linux docker container for simplicities sake.

As for docker containers, we will look at 2 base images as starting points for our own images:

1. [bitnami/mindeb](https://hub.docker.com/r/bitnami/minideb)
2. [alpine](https://hub.docker.com/_/alpine)

The process is very similar for both of them, but does contain minor differences, particularly in the dockerfile and commands needed to compile your project.

The examples in this guide assume that:

1. You have a server
2. You can ssh into your server
3. You can copy files to your server via e.g. scp
4. You have set up your server with a domain name

## Compile your binary
Compiling your binary is very different between alpine and other linux images.
This is because unlike most other linux distributions, alpine does not use the `gnu c library` (glibc) to link all its binaries against.
Instead it uses `musl`, which is much more minimalistic.

Because your binary is at its core linked to these libraries, you will need to compile them in different ways in order for one to link with `glibc` and the other to link with `musl`.

### On bitnami/mindeb
bitnami/minideb is basically a stripped down version of debian, reduced to the bare essentials.

Since it is fundamentally a debian image, that means it will have the `gnu c library` (glibc) available, which is the main advantage of this image. 

Since the overwhelming majority of Linux systems use `glibc` to link their C binaries, compiling on any Linux distro will give you a binary that is dynamically linked against your `glibc` version and thus is likely to work in the image.
If you have to ask yourself whether your distro is using `glibc`, you are using `glibc`.

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

If you want to avoid re-typing all the flags you want to set, you can centrally define them in a [nimble task](https://github.com/nim-lang/nimble#nimble-tasks) that you can trigger instead!
Just add the following to your `<YOUR_PROJECT>.nimble` file (run [`nimble init`](https://github.com/nim-lang/nimble#nimble-init) if you don't have one yet):

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
This is unlikely to have any performance implications for your application, but it does speed up deploying the image since it uploads faster to your server due.

Due to its usage of `musl` as core lib instead of `glibc`, compiling your project will look a little bit different.
For simplicities sake, we will still be linking to musl dynamically.

#### Install musl
You will first need to install musl.
To do so, just follow these steps:

1. [download](https://www.musl-libc.org/download.html) the tar file
2. Unpack the tar file somewhere
3. Run `bash configure` in the unpacked directory. WARNING: Make sure that you do NOT install musl with `--prefix` being  `/usr/local`, as that may adversely affect your system. Use somewhere else where it is unlikely to override files, e.g. `/usr/local/musl`. This path will further be referred to as `<MUSL_INSTALL_PATH>`
4. Run `make && make install` in the unpacked directory
5. Add `<MUSL_INSTALL_PATH>` to your PATH environment variable
6. Validate whether you set everything up correctly by opening a new terminal and seeing whether you have access to the `musl-gcc` binary

#### Compiling your dynamically linked musl binary
Similarly to before, you can write yourself a compile command. 
This time though, we need to swap out the compiler that is used. Instead of `gcc`, we want to use `musl-gcc` in order to dynamically link with `musl` instead of `glibc`.
We similarly want to replace the linker with `musl-gcc`.
We can use the flags `--gcc.exe:"musl-gcc"` and `--gcc.linkerexe:"musl-gcc"` to get a compile command similar to the one used for `bitnami/minideb`:

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

Analogous to `bitnami/minideb` we can set up a nimble task instead:
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
For our docker container to run properly, we will need to:

1. Set up the server to have SSL certificates with certbot to get `fullchain.pem` and `privkey.pem` files
2. Write an `nginx.conf` file to configure nginx
3. Write a bash file `dockerStartupScript.sh` to run inside the docker container when starting it.
4. Write a `settings.json` file for prologue

We will store these files in a directory called `buildFiles` and include them in our docker image later.

### Set up your server to have SSL certificates with certbot
There are many great resources on how you can get free SSL certificates for use with your web-application.
We recommend using [certbot](https://certbot.eff.org/instructions) for this purpose. Follow the instructions on their website to set yourself up.

As a sidenote though, make sure you set up a mechanism to renew your certificates regularly, to make sure they do not expire.

### Configuring nginx
Nginx requires a config file, `nginx.conf` to serve any media files and forward requests to our prologue backend.

Here we'll set nginx up to use SSL with the SSL certificates received from the previous step.
Further, for nginx to forward requests to a prologue backend, we can make use of its "proxy_pass" directive.

Keep in mind that all of these directories will be filepaths within the *docker* container, not your actual server.

See below an example of a small nginx.conf file:
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

Note that the file assumes there will be a `fullchain.pem` and `privkey.pem`, which you currently have on your server (e.g. `/etc/letsencrypt/live`). We will make these certificates accessible by creating the `/cert/live` directories inside the docker image and mounting the certificate directory to that folder when creating a container via [docker volumes](https://docs.docker.com/storage/volumes/).

For now though, store your nginx.conf file locally in `./buildFiles/nginx.conf`.

### Provide a startup script for your docker container
For convenience reasons, we want our nginx server and prologue server to automatically start when we start the docker container.
To achieve this, we need to provide a simple shell script that can be executed when the container starts. 
Usually this would be done using systemd, for our smaller image though we will be using the simpler `openrc`.

```bash
#!/bin/sh
# This file contains all commands that shall be run on the docker container on startup
openrc boot # Enables running rc-service, which manages nginx
rc-service nginx start # Starts up nginx
/<YOUR_BINARY> # Starts your prologue application
```

Store your script file locally in `./buildFiles/dockerStartupScript.sh`.

### Provide a config file for prologue
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
Store your settings file locally in `./buildFiles/settings.json`.

## Write your dockerfile
After completing the prior steps, we can start writing a `dockerfile`.
It will contain the instructions necessary to create a docker image, from which containers can be made.

This process differs slightly between `bitnami/minideb` and `alpine`, since `alpine` uses `apk` to install packages from the [alpine repositories](https://alpine.pkgs.org/?) while `bitnami/minideb` uses apt to install [debian packages](https://www.debian.org/distrib/packages). This means the commands look slightly different and the names of the packages also differ slightly.

Additionally to installing packages, we will be setting up various folders ahead of time, in order to use them as mounting points for [docker volumes](https://docs.docker.com/storage/volumes/) when creating containers from our images. 
This way you can access files inside the container (e.g. media files so that nginx can serve them, or an sqlite database) without risking loosing them should the container crash or be removed.

### On `bitnami/minideb`
In order to install packages without having to deal with `apt`'s commandline prompts, this image ships a `install_packages` command.
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

### On `alpine`
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

## Build the docker image
With the binary, buildFiles and dockerfile ready, you can create your image:

```sh
# Creates your image
sudo docker build -t <YOUR_IMAGE_NAME> .
# Stores your image in your current working directory in a file called "image.tar"
sudo docker save -o image.tar <YOUR_IMAGE_NAME>
```

Once created, move that image file to your server, e.g. through `scp`.

## Run the docker image on your server
After copying your `image.tar` file to the server, you can load it there with docker and run a container from it.
Besides starting the container, the commands needs to:

1. Open up the HTTP port (80)
2. Open up the HTTPS port (443)
3. Mount all the volumes for certificates, media files to connect folders on your server to folders on your docker container etc.

Opening up the ports is done using `-p`, mounting the volumes with `-v`.
Note that in `-v`, the first path is the one *outside* of your container. It specifies which folder on your server to mount. The second path is the one *inside* your container. It specifies where to mount the server folder in your container.

You may want to write yourself a small script that loads the file, stops and removes any previously running container of the sort before creating a new one from the new image. Here an example:
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

Once done, all you need to do is run the command (or script), and your container will start up and be accessible via HTTP and HTTPS!

## Known issues
### Compile your binary (under `bitnami/minideb` - `error "/lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_<X.XX>' not found"`
You will run into this issue if your local `glibc` version is more up-to-date than the one `bitnami/minideb` has access to.
This is the case because during compilation your binary is dynamically linked with your local `glibc` version.
That means in order to run, it expects the environment that executes it to have *at least* that same glibc version.

To fix this, you need to link your binary to an older glibc version when compiling, even though your own version is newer.
[Doing so is not straightforward.](https://stackoverflow.com/questions/2856438/how-can-i-link-to-a-specific-glibc-version)

#### Solution 1: Using zig
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

#### Solution 2: Create a compilation environment
Instead of using zig, you can set up a second docker container that contains the glibc version you want, gcc, nim, nimble and the C-libs you require. 
You can then mount your project-folder via [docker volume](https://docs.docker.com/storage/volumes/) in the container and compile as normal.
Then, you can just compile your binary within the container as usual, your normal compilation command.
