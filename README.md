# Runic Realms Kustomization Stack
This is the basic set of manifests that should be applied on top of a K3s cluster.

In the future this will be moved to use something like Ansible to ensure declarative configuration.

## Setup Steps

### Installation
- Install K3s with default configuration
  - You should disable the traefik installation with the `--disable=traefik` flag. This is because we will install it manually for greater control.
- Install K9s, Helm, Kustomize
- Duplicate all files that end in .template (these are secrets that need to be filled in)
- Apply the stack with `./apply.sh`

### Tailscale and Cloudflare
- The current setup involves a cluster that is completely hidden behind a tailscale VPN.
  - Cloudflare manages DNS resolution and points all subdomains (`registry`, `argocd`, `nexus`, `jenkins`) to the k3s node IP in the tailscale network.
    - These connections cannot be proxied through cloudflare
  - The tailscale network must have the setting for automatic HTTPS <b>disabled</b>
    - This is because it will attempt to overwrite our existing letsencrypt certs causes much pain
- You must create a cloudflare API key with the following permissions:
  - Zone.zone read
  - Zone.DNS edit
  - Permission to see the correct domain project (`runicrealms.com`)
- This API Key must be supplied to `traefik/cloudflare-secret.yaml`. Ensure to not include a newline in this secret.
- If all is setup correctly, you should now be able to access subdomains `registry`, `argocd`, `nexus` and `jenkins` when connected to tailscale, with proper letsencrypt TLS certs (created with DNS-01 challenge).

### Passwords
- Modify the harbor password at `registry.runicrealms.com` from the default
- Get and modify the argocd default admin password at `argocd.runicrealms.com` from the default
- Create a jenkins user at `jenkins.runicrealms.com`

### Harbor
- Login to `registry.runicrealms.com`, create a project named `build` and a project named `jenkins`. There should also be a default one called `library`.
- Create a robot user named `jenkins` (will be named `robot$jenkins`) with permission to read/modify all repositories in projects `build`, `jenkins` and `library`
  - At this stage you need to go back and update the `regcred` secret you installed in the `jenkins` namespace with this robot password

### Nexus
- Login to `nexus.runicrealms.com`, create an admin password
- Make sure to allow anonymous pulls from nexus

### Jenkins
Install plugins:
- Docker
- Kubernetes for Jenkins
- Git/GitHub
- Pipeline Utility Steps
- Discord Notifier

Add Kubernetes Cloud:
- Named `kubernetes`
- Namespace `jenkins`
- Jenkins URL `http://jenkins.jenkins.svc.cluster.local:8080`
- Everything else default/blank

Add credentials:
- GitHub:
  - SSH credential type
  - ID `github-ssh`
  - Username `git`
  - Private RSA key you generate, and add to the corresponding GitHub account
  - For us, this account is @RunicRealmsGitHub on GitHub
- GitHub PAT
  - Secret text type
  - ID `github-pat`
  - Value should be a PAT with permission to create PRs on @RunicRealmsGithub
- Discord: For the discord webhook
  - type: secret text
  - ID `discord-webhook`
  - Secret is just the discord-generated URL webhook
- Docker registry:
  - Type is basic user/pass
  - Username should be `robot$jenkins`
  - Password is the one generated that harbor gave you
  - ID `docker-registry-credentials`
- Nexus:
  - Type is base user/pass
  - ID `nexus-credentials`
  - Username and password should come from your Nexus login

Add global trusted pipeline library (manage jenkins -> system):
- Named `Jenkins-Shared-Lib`
- Default ref `main`
- Points to modern SCM with git@github.com:Runic-Studios/Jenkins-Shared-Lib, using our stored git credentials
- Uses credentials that we defined earlier

Modify security settings:
- Navigate to Manage Jenkins -> Security -> Git Host Key Verification Configuration, change to "Accept First Connection"

Create multi-branch build configurations for the following projects:
- Names: `Realm-Velocity`, `Velagones`, `Trove`
- SCMs: `git@github.com:Runic-Studios/Realm-Velocity.git`, `git@github.com:Runic-Studios/Velagones.git`, `git@github.com:Runic-Studios/Trove.git`
- Branches filter by expression `dev|main`
- Discard old items after 7 days

