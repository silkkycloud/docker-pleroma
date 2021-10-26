# Pleroma Docker Image

This is our Pleroma docker image. This is a image which is currently deployed at https://social.silkky.cloud/

Advanatges of our image:
- Hardened Malloc
- Tini init manager
- Uses official Pleroma's Docker config
- Build from source code and uses by default stable branch
- Rootless image
- The image is being scanned by Trivy once a day

# How to adopt for yourself
Check the config.exs file and configurate it as you wish, next check which branch you want to use (by default it is stable one)
Our docker compose is here https://github.com/silkkycloud/deploy-pleroma
Our proxy deploy is here https://github.com/silkkycloud/deploy-pleroma-proxy (optional if you don't use media proxy)
