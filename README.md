![License MIT](https://img.shields.io/badge/license-MIT-blue.svg) [![](https://img.shields.io/docker/stars/unclev/prosody-docker-extended.svg)](https://hub.docker.com/r/unclev/prosody-docker-extended 'DockerHub') [![](https://img.shields.io/docker/pulls/unclev/prosody-docker-extended.svg)](https://hub.docker.com/r/unclev/prosody-docker-extended 'DockerHub')
# prosody-docker-extended
Docker image building system for the Prosody XMPP server with Community Modules and telnet console.
This project was inspired by the [official Prosody Docker](https://github.com/prosody/prosody-docker/) and particularly to overcome this issue prosody/prosody-docker#29.

## Building

```
docker build --rm=true -t unclev/prosody-docker-extended .
```

It is available at [Docker Hub](https://hub.docker.com/r/unclev/prosody-docker-extended/).

The [Docker Hub](https://hub.docker.com/r/unclev/prosody-docker-extended/) images are now re-builds within an hour after each nightly build in the official Prosody deb [repository](https://prosody.im/download/package_repository).

## prosody-docker-extended features
### Ports

The image exposes the following ports to the docker host:

* __80__: HTTP port
* __443__ HTTPS port
* __5222__: c2s port
* __5269__: s2s port
* __5347__: XMPP component port
* __5280__: BOSH / websocket port
* __5281__: Secure BOSH / websocket port

Note: These default ports can be changed in your configuration file. Therefore if you change these ports will not be exposed.

### Volumes
Volumes can be mounted at the following locations for adding in files:

* __/etc/prosody__:
  * Prosody configuration file(s)
  * SSL certificates
  * Note: the [starter](https://github.com/unclev/prosody-docker-extended/blob/master/entrypoint.sh#L7) copies the pre-configured at build time data into this location if it empty.
* __/var/lib/prosody__:
  * Prosody internal data storage (see [Data storage](https://prosody.im/doc/storage) at the Prosody web site)
* __/var/log/prosody__:
  * Log files for prosody - by default it is not used by prosody-docker-extended container, logs go to console and visible via [docker logs](https://docs.docker.com/engine/reference/commandline/logs/).
  * Note: This location can be changed in the configuration, update to match
  * Also note: The log directory on the host (/logs/prosody in the example below) must be writeable by the prosody user
* __/usr/lib/prosody/modules-community__:
  * Location for including community modules
  * Note: The image has it pre-configured in the config file, the [starter](https://github.com/unclev/prosody-docker-extended/blob/master/entrypoint.sh#L21-L22) clones https://hg.prosody.im/prosody-modules/ into this location if it is empty.
* __/usr/lib/prosody/modules-custom__:
  * Location for including additional modules
  * The image has the modules locations pre-configured as per [installing_modules](http://prosody.im/doc/installing_modules#paths) at the Prosody web site.

```lua
-- These paths are searched in the order specified, and before the default path
plugin_paths = { "/usr/lib/prosody/modules-custom", "/usr/lib/prosody/modules-community" }
```
### Prosody user
There is a user with uid=1000(prosody) gid=1000(prosody) groups=1000(prosody) in the __prosody-docker-extended__ image.

### Adding a jabber user at startup
For compatibility with prosody/prosody-docker a user can be created by using environment variables `LOCAL`, `DOMAIN`, and `PASSWORD`. This performs the following action on startup:
> prosodyctl register *local* *domain* *password*

Prosody will not check the user exists before running the command (i.e. existing users will be overwritten). It is expected that [mod_admin_adhoc](http://prosody.im/doc/modules/mod_admin_adhoc) will then be in place for managing users (and the server).

### Examples
```bash
docker run -d \
   --name prosody_xmpp_server \
   --hostname shakespeare.lit \
   -p 5222:5222 \
   -p 5269:5269 \
   -p localhost:5347:5347 \
   -e LOCAL=romeo \
   -e DOMAIN=shakespeare.lit \
   -e PASSWORD=juliet4ever \
   -v /srv/prosody/config:/etc/prosody \
   -v /srv/prosody/data:/var/lib/prosody \
   -v /srv/prosody/log:/var/log/prosody \
   -v /srv/prosody/modules/community:/usr/lib/prosody/modules-community \
   -v /srv/prosody/modules/custom:/usr/lib/prosody/modules-custom \
   unclev/prosody-docker-extended:0.10
```

docker-compose.yml (v1) with PostgreSQL backend:

```yaml
sql:
  image: postgres
  restart: always
  env_file: /srv/prosody/.env
  ports:
    - '5432:5432'
  volumes:
    - '/srv/prosody/db/postgresql:/var/lib/postgresql/prosody'

xmpp_server:
  image: unclev/prosody-docker-extended:0.10
  restart: unless-stopped
  hostname: shakespeare.lit
  ports:
    - 5222:5222
    - 5269:5269
    - 5347:5347
    - 5280:5280
  env_file: /srv/prosody/.env
  links: 
    - sql:sql
  volumes:
    - '/srv/prosody/config:/etc/prosody'
    - '/srv/prosody/data:/var/lib/prosody'
    - '/srv/prosody/log:/var/log/prosody'
    - '/srv/prosody/modules/community:/usr/lib/prosody/modules-community'
    - '/srv/prosody/modules/custom:/usr/lib/prosody/modules-custom'
```

### Starting the container shell
Connect to a linux shell of a running __prosody-docker-extended__ container (or any other executable resides in the container) is easy:
```bash
docker exec -it prosody_xmpp_server bash
```
or with docker-compose
```bash
docker-compose exec xmpp_server bash
```

this brings linux shell with *prosody* user.

Explicitly specify `--user root` if you want root shell. See [docker exec](https://docs.docker.com/engine/reference/commandline/exec/) for more details. 

### Telnet console
__prosody-docker-extended__ comes with telnet. Enabling [mod_admin_telnet](https://prosody.im/doc/modules/mod_admin_telnet) plugin (as of now it is not enabled by default) starts a telnet console to let you communicate with a running prosody server.
```bash
docker exec -it prosody_xmpp_server telnet localhost 5582
```

or with docker-compose

```bash
docker-compose exec xmpp_server telnet localhost 5582
```
For information on the telnet console see [Console](https://prosody.im/doc/console) in the Prosody documentation.

It does not make sense requesting __server:shutdown__ via the telnet console as in most configurations a container with the server restarts.

### prosodyctl
Using [prosodyctl](https://prosody.im/doc/prosodyctl) to control the server is aslo possible. 
See the Prosody documentation: [prosodyctl](https://prosody.im/doc/prosodyctl).

It does not make sense requesting __start__, __stop__, __restart__ commands of *prosodyctl*, as prosody process is not started as a daemon within a container.

Note: do not change the pre-defined
```lua
daemonize = false;
```
setting in the prosody.cfg.lua.

__To restart the server__ you can stop, remove, and re-start the container itself. For example, the only *prosody_xmpp_server_1* container with docker-compose:
```
victor@unclev:/srv/prosody$ docker-compose stop xmpp_server && docker-compose rm -f xmpp_server && docker-compose up -d
```
or just 
```bash
docker-compose down && docker-compose up -d
```
the last stops and re-starts all the services in the docker composition.

### Community modules
For information on community modules address the Prosody documentation: [community modules](https://prosody.im/community_modules).

The __prosody-docker-extended__ image comes with [Mercurial SCM](https://www.mercurial-scm.org/) installed in it. 
The container clones https://hg.prosody.im/prosody-modules/ into `/usr/lib/prosody/modules-community` when it starts in the name of the *prosody* user. 
Normally you should map `/usr/lib/prosody/modules-community` to a persistent location (on your docker host or a data container).

Even though the repository support within the image is very limited by (some modules may add files into their folders within the repo, which may prevent the repo from being updated). However, you can control [community modules](https://hg.prosody.im/prosody-modules/) from the container shell.
```
victor@unclev:/srv/prosody$ docker-compose exec xmpp_server bash
prosody@unclev:/$ cd /usr/lib/prosody/modules-community   
prosody@unclev:/usr/lib/prosody/modules-community$ hg status
? mod_admin_web/admin_web/www_files/css/bootstrap-1.4.0.min.css
? mod_admin_web/admin_web/www_files/js/adhoc.js
? mod_admin_web/admin_web/www_files/js/jquery-1.10.2.min.js
? mod_admin_web/admin_web/www_files/js/strophe.min.js
? mod_mam_archive/SciTE.properties
prosody@unclev:/usr/lib/prosody/modules-community$ hg pull --update
pulling from https://hg.prosody.im/prosody-modules/
searching for changes
no changes found
```

### Custom modules
As a workaround you can put modules being used in your persistent location and map `/usr/lib/prosody/modules-custom` to it.

The __prosody-docker-extended__ image is configured to look for modules under this location first.

### Logs
The Prosody server within the __prosody-docker-extended__ image is configured to log to "console" (see [advanced_logging](https://prosody.im/doc/advanced_logging) in the Prosody documentation). 
This prevents contamination of the newly created container with such garbage.

Use mapping of `/var/log/prosody` directory want set up logs in a persistent location (likely - your docker host).

There is an example in [Information for packagers - logging](https://prosody.im/doc/packagers#logging) in the Prosody documentation. 
```lua
log = {
        -- Log all error messages to prosody.err
        { levels = { min = "error" }, to = "file", filename = "/var/log/prosody/prosody.err" };
        -- Log everything of level "info" and higher (that is, all except "debug" messages)
        -- to prosody.log
        { levels = { min =  "info" }, to = "file", filename = "/var/log/prosody/prosody.log" };
    }
```
__Log rotation__ is supposed to be set up on your docker host. The prosody-docker-extended image itself does not support log rotation.

## Configuring Prosody IM server
Configuring Prosody IM XMPP communication server resided within the __prosody-docker-extended__ container is generally the same as configuring a standalone Prosody IM server, 
but please don't forget specifying internal container paths, - not the external mapped paths, in the prosody config.
Please see the official Prosody IM documentation on [configuring Prosody](https://prosody.im/doc/configure).
