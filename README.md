# Tools

Image Docker multi-architecture (Alpine 3.23) contenant des outils DevOps :
- Terraform 1.10.1
- Google Cloud SDK 458.0.0 (kubectl, gke-gcloud-auth-plugin)
- AWS CLI
- Docker CLI 27.2.0
- Cloudflared
- Ansible
- Git, Make, jq, bind-tools, etc.

## Build local

```bash
docker build -t kwop/tools:local .
```

## Tester l'image

```bash
docker run --rm kwop/tools:local terraform version
docker run --rm kwop/tools:local gcloud version
docker run --rm kwop/tools:local aws --version
docker run --rm kwop/tools:local docker --version
docker run --rm kwop/tools:local ansible --version
```

## Build multi-architecture et push

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t kwop/tools:<version> --push ./
```
