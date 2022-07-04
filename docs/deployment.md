# An example deployment on Linux with nginx inside of a docker container
This is an example of how you can deploy a prologue web-application that was compiled under Linux.
This example will use nginx as a reverse proxy for the prologue application, both within the same container for simplicities sake.

This example assumes that:
1. You have a server
2. You can ssh into your server
3. You can copy files to your server via e.g. scp
4. You have set up your server with a domain name

## Compile your binary
On any normal Linux system, you typically compile with gcc and dynamically link to your local installation of `glibc`.
Since you likely want to enable various flags, it makes sense to set up a nimble task for this:

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

Add the above to your `<YOUR_PROJECT>.nimble` file.
This allows you to run `nimble release` in your project to compile it with the flags specified in there!

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

We will base this image off of `bitnami/minideb`, a minimal debian image that contains glibc and apt for installing further packages.

As a sidenote, we will be setting up various folders ahead of time, in order to use them as mounting points for [docker volumes](https://docs.docker.com/storage/volumes/) when creating containers from the image. 
This way you can access files inside your container (e.g. media files so that nginx can serve them, or an sqlite database) without risking loosing them should the container crash or be removed.

Here an example of how this can look like:
```txt
FROM bitnami/minideb

# Install dependencies
RUN apt update
RUN install_packages openrc openssl nginx
# RUN install_packages sqlite3 # in case you use an sqlite3 database

# Copy necessary files, the first paths are all relative to your current working directory
COPY ./path/to/your/binary .
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

With the binary, buildFiles and dockerfile ready, you can create your image and move that image to your server:

```sh
# Creates your image
sudo docker build -t <YOUR_IMAGE_NAME> .#
# Stores your image in your current working directory in a file called "image.tar"
sudo docker save -o image.tar <YOUR_IMAGE_NAME>
```

## Run the docker image on your server
After copying your `image.tar` file to the server, you can load it there with docker and run a container from it.
Besides starting the container, the commands needs to:

1. Open up the HTTP port (80)
2. Open up the HTTPS port (443)
3. Mount all the volumes for certificates, media files etc.

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
### Compile your binary - `error "/lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_<X.XX>' not found"`
You will run into this issue if your local glibc version is more up-to-date than the one bitnami/minideb has access to.
This is the case because during compilation your binary is dynamically linked with your local glibc version.
That means in order to run, it expects the environment that executes it to have *at least* that same glibc version in order to make system calls etc. .

To fix this, you need to link your binary to an older glibc version when compiling.
[Doing so is not straightforward.](https://stackoverflow.com/questions/2856438/how-can-i-link-to-a-specific-glibc-version)

#### Solution 1: Using zig

The simplest way is installing the [zig programming language](https://ziglang.org/download/), as it contains a Clang compiler, which you can tell which glibc version to use.

The steps go as follows:
1. Install zig
2. Write a bashscript called `zigcc`
```sh
#!/bin/sh
zig cc $@
```
3. Move `zigcc` to somewhere on your path, e.g. `/usr/local/bin`.
This is required since the nim compiler does not tolerate spaces in commands that call compilers.
4. Write yourself a bashscript with a command to compile your project. 
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
5. Run projectCompile.sh

#### Solution 2: Create a compilation environment

Instead of using zig, you can set up a second docker container that contains the glibc version you want, gcc, nim, nimble and the C-libs you require. 
You can then mount your project-folder via [docker volume](https://docs.docker.com/storage/volumes/) in the container and compile as normal.
Then, you can just compile your binary within the container as usual, your normal compilation command.