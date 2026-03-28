#!/bin/sh
set -e

PATH=/opt/sbin:/opt/bin:$PATH
export PATH

# --- Realms ---
i=1
while true; do
    eval "domain=\$REALM_${i}_DOMAIN"
    [ -z "$domain" ] && break
    eval "client_id=\$REALM_${i}_CLIENT_ID"
    eval "client_secret=\$REALM_${i}_SECRET"
    cat >> /etc/raddb/proxy.conf <<EOF
realm $domain {
    oauth2 {
        discovery = "https://login.microsoftonline.com/%{Realm}/v2.0"
        client_id = "$client_id"
        client_secret = "$client_secret"
        cache_password = yes
    }
}
EOF
    i=$((i + 1))
done

# --- Clients ---
i=1
while true; do
    eval "name=\$CLIENT_${i}_NAME"
    [ -z "$name" ] && break
    eval "network=\$CLIENT_${i}_NETWORK"
    eval "secret=\$CLIENT_${i}_SECRET"
    cat >> /etc/raddb/clients.conf <<EOF
client $name {
    ipaddr = $network
    secret = $secret
}
EOF
    i=$((i + 1))
done

# this if will check if the first argument is a flag
# but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- radiusd "$@"
fi

# check for the expected command
if [ "$1" = 'radiusd' ]; then
    shift
    exec radiusd -f "$@"
fi

# debian people are likely to call "freeradius" as well, so allow that
if [ "$1" = 'freeradius' ]; then
    shift
    exec radiusd -f "$@"
fi

# else default to run whatever the user wanted like "bash" or "sh"
exec "$@"
