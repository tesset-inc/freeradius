# FreeRadius with AzureAD authentication

Docker image, tailored to be launched in Azure Container Instances, to provide a Radius server that authenticates users with Azure AD without and Domain Services using [freeradius-oauth2-perl](https://github.com/jimdigriz/freeradius-oauth2-perl).

## BREAKING: Move from DockerHub to Github Packages

Due to [`Free Team`](https://www.docker.com/blog/we-apologize-we-did-a-terrible-job-announcing-the-end-of-docker-free-teams/) tier being sunset by DockerHub, ARK is going to deprecate Docker image repository.

Update your deployments from `arkenergy/freeradius-azuread:latest` to `ghcr.io/arklab/freeradius-azuread:latest`.


# How to

1. Setup an Azure AD Application as illustrated in the [freeradius-oauth2-perl](https://github.com/jimdigriz/freeradius-oauth2-perl) project.
2. Spin up `ghcr.io/arklab/freeradius-azuread:latest` image with the environment variables described below.

## Environment variables

Configure realms and clients using indexed environment variables with a numeric suffix starting at `1`. The entrypoint processes them sequentially and stops at the first missing index.

### Realm variables

| Env | Description |
|--|--|
| REALM_{N}_DOMAIN | The Azure AD domain for realm N |
| REALM_{N}_CLIENT_ID | The OAuth2 client ID for realm N |
| REALM_{N}_SECRET | The OAuth2 client secret for realm N |

### Client variables

| Env | Description |
|--|--|
| CLIENT_{N}_NAME | The NAS client name for client N |
| CLIENT_{N}_NETWORK | The allowed network/IP for client N |
| CLIENT_{N}_SECRET | The shared secret for client N |

### Docker run example

```
docker run -p 1812:1812/udp -p 1813:1813/udp \
  -e REALM_1_DOMAIN='example.com' \
  -e REALM_1_CLIENT_ID='aaa-bbb-ccc' \
  -e REALM_1_SECRET='secret1' \
  -e REALM_2_DOMAIN='contoso.com' \
  -e REALM_2_CLIENT_ID='ddd-eee-fff' \
  -e REALM_2_SECRET='secret2' \
  -e CLIENT_1_NAME='PFSense' \
  -e CLIENT_1_NETWORK='172.28.0.4/32' \
  -e CLIENT_1_SECRET='nassecret1' \
  -e CLIENT_2_NAME='AccessPoint' \
  -e CLIENT_2_NETWORK='10.0.0.0/24' \
  -e CLIENT_2_SECRET='nassecret2' \
  ghcr.io/arklab/freeradius-azuread:latest
```

### Docker Compose

```yaml
services:
  freeradius:
    image: ghcr.io/arklab/freeradius-azuread:latest
    ports:
      - "1812:1812/udp"
      - "1813:1813/udp"
    env_file:
      - .env
    restart: unless-stopped
```

All realm and client variables are defined in a `.env` file. Add or remove entries as needed without modifying `docker-compose.yml`. See `.env.example` for the expected format.

# Security caveat

For this to work the NAS should use PAP authentication, meaning the clear-text password is received by the RADIUS server.
Adding that to the fact that this image doesn't support RADSEC TLS between NAS client and RADIUS server, means that the clear-text password is transferred unencryped between the NAS client and the RADIUS server.

**Do not use this image if the channel between the NAS and this RADIUS server is unsecure.**
