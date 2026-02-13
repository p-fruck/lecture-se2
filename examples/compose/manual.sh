#!/bin/sh
set -x
net=test; client=pgclient; server=pgserver
pg_password='p4$$w0rd'; pg_version=18-alpine
# Create network and launch detached server
podman network create ${net}
podman run --rm --name ${server} --network ${net} -e POSTGRES_PASSWORD=${pg_password} \
  -d postgres:${pg_version}
# Wait some time to avoid race condition
sleep 3
# Run the client (note different password variable)
podman run --rm --name ${client} --network ${net} -e PGPASSWORD=${pg_password} \
  --entrypoint psql postgres:${pg_version} -h ${server} -U postgres -c "SELECT version();"
# clean up
podman rm -f ${client} ${server} && podman network rm -f ${net}
