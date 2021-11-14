# Pleroma Docker Image

This is our Pleroma docker image. This is a image which is currently deployed at https://social.silkky.cloud/

Advanatges of our image:
- Hardened Malloc
- Tini init manager
- Uses official Pleroma's Docker config
- Build from source code and uses by default stable branch
- ~~Rootless image~~ (Needs to be fixed see: [#4](https://github.com/silkkycloud/docker-pleroma/issues/4))
- The image is being scanned by Trivy once a day

## How to config

The container expects to find a Pleroma configuration file at `/etc/pleroma/config.exs`. If the configuration does not exist, the container will call `pleroma_ctl instance gen` for you. 

**WARNING: Even if you don't have a config and you letting the container generate it, it is important to have the generated configuration in `/etc/pleroma`!**

The three environment variables you MUST supply are:

- `DOMAIN`
- `ADMIN_EMAIL`
- `POSTGRES_PASSWORD`

In case if you want to use your own repository with Pleroma backend then you must also fill these variatables as well!
By default it will use official git repo, at stable branch.

- `PLEROMA_GIT_REPO` - link to the git repo
- `PLEROMA_VERSION` - will use specific branch of repo

| Arg | Env | Default value of env |
| -------- | ------------------- | ------------- |
| `--domain` | `DOMAIN` | _none_ |
| `--instance-name` | `INSTANCE_NAME` | same as `DOMAIN` |
|  `--admin-email` | `ADMIN_EMAIL` | _none_ |
| `--notify-email` | `NOTIFY_EMAIL` | same as `ADMIN_EMAIL` |
| `--dbhost` | `POSTGRES_HOST` | postgres  |
| `--dbname` | `POSTGRES_DB` | pleroma  |
| `--dbuser` | `POSTGRES_USER` | pleroma  |
| `--dbpass` | `POSTGRES_PASSWORD` | _none_ |
| `--rum` | `USE_RUM` | n |
| `--indexable` | `INDEXABLE` | y  |
| `--db-configurable` | `DB_CONFIGURABLE` | y  |
| `--uploads-dir` | `UPLOADS_DIR` | /var/lib/pleroma/uploads  |
| `--static-dir` | `STATIC_DIR` | /var/lib/pleroma/static  |
| `--listen-ip` | `LISTEN_IP` | 0.0.0.0  |
| `--listen-port` | `LISTEN_PORT` | 4000 |
| `--strip-uploads` | `STRIP_UPLOADS` | y |
| `--anonymize-uploads` | `ANONYMIZE_UPLOADS` | y |
| `--dedupe-uploads` | `DEDUPE_UPLOADS` | y |

If you wish to have Soapbox instead of Pleroma-FE, then you can set an environment variable USE_SOAPBOX to "y". 

Then, use docker-compose file here https://github.com/silkkycloud/deploy-pleroma
It will mount at these directories:

- `/etc/pleroma` as read-only for container
- `/var/lib/pleroma/static`
- `/var/lib/pleroma/uploads`
