# prosody-docker-extended
Docker image building system for the Prosody XMPP server with Community Modules and telnet console.

## Build

```
docker build --build-arg PROSODY_VERSION="" --rm=true -t prosody:stable .
```

Where PROSODY_VERSION can also be -trunk, -0.10, -0.9 for nightly builds.

It is available at [Docker Hub](https://hub.docker.com/r/unclev/prosody-docker-extended/).
The tags are: latest, 0.10, 0.9, for prosody-trunk, prosody-0.10, prosody-0.9 accordingly, "stable" tag for prosody with no version specified (as per above).

## Description
TBA
