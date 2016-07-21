FROM ubuntu:xenial
MAINTAINER Victor Kulichenko <onclev@gmail.com>
#ARG PROSODY_VERSION
ENV PROSODY_VERSION="-0.10" \
    PUID=${PUID:-1000} PGID=${PGID:-1000} \
    PROSODY_MODULES=/usr/lib/prosody/modules-community \
    CUSTOM_MODULES=/usr/lib/prosody/modules-custom
ADD https://prosody.im/files/prosody-debian-packages.key /root/key
COPY prosody.list /etc/apt/sources.list.d/
COPY ./entrypoint.sh /entrypoint.sh
COPY ./update-modules.sh /usr/bin/update-modules

# create prosody user with uid and gid predefined
RUN groupadd -g $PGID -r prosody && useradd -b /var/lib -m -g $PGID -u $PUID -r -s /bin/bash prosody

# install prosody, mercurial, and recommended dependencies, prosody-modules locations, tweak and preserve config
RUN set -x \
 && apt-key add /root/key && rm /root/key \
 && apt-get update -qq \
 && apt-get install -qy telnet \
    apt-utils mercurial lua-sec lua-event lua-zlib lua-ldap \
    lua-dbi-mysql lua-dbi-postgresql lua-dbi-sqlite3 lua-bitop \
    prosody${PROSODY_VERSION} \
 && apt-get purge apt-utils -qy \
 && apt-get clean && rm -Rf /var/lib/apt/lists \
 && sed -i -e '1s/^/daemonize = false;\n/' -e 's/daemonize = true/-- daemonize = true/g' /etc/prosody/prosody.cfg.lua \
 && perl -i -pe '$_ = qq[\n-- These paths are searched in the order specified, and before the default path\nplugin_paths = { \"$ENV{CUSTOM_MODULES}\", \"$ENV{PROSODY_MODULES}\" }\n\n$_] if $_ eq qq[modules_enabled = {\n]' \
         /etc/prosody/prosody.cfg.lua \
 && perl -i -pe 'BEGIN{undef $/;} s/^log = {.*?^}$/log = {\n    {levels = {min = "info"}, to = "console"};\n}/smg' /etc/prosody/prosody.cfg.lua \
 && cp -Rv /etc/prosody /etc/prosody.default && chown prosody:prosody -Rv /etc/prosody /etc/prosody.default \
 && mkdir -p "$PROSODY_MODULES" && chown prosody:prosody -R "$PROSODY_MODULES" && mkdir -p "$CUSTOM_MODULES" && chown prosody:prosody -R "$CUSTOM_MODULES" \
 && chmod 755 /entrypoint.sh /usr/bin/update-modules

VOLUME ["/etc/prosody", "/var/lib/prosody", "/var/log/prosody", "$PROSODY_MODULES", "$CUSTOM_MODULES"]

USER prosody

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80 443 5222 5269 5347 5280 5281
ENV __FLUSH_LOG yes
CMD ["prosody"]

