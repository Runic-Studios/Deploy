
# Runic Realms Kustomization Stack
This is the basic set of manifests that should be applied on top of a K3s cluster.

In the future this will be moved to use something like Ansible to ensure declarative configuration.

## Setup Steps

### Installation
- Install K3s with default configuration
  - You should disable the traefik installation with the `--disable=traefik` flag. This is because we will install it manually for greater control.
- Install K9s, Helm, Kustomize
- Install bitnami [sealed-secrets client](https://github.com/bitnami-labs/sealed-secrets/releases)
- Duplicate all files that end in .template (these are secrets that need to be filled in)

### Configure Secrets
- Using the `kubeseal` client, re-generate the public certificate for your cluster by running `secret/gen-pub.sh`
  - You should copy and commit this file to the one that exists in the Realm-Deployment argocd repo
- Run the secret generation scripts:
  - Jenkins registry credentials:
    - Rename dockerconfig.json.template to dockerconfig.json and fill in credentials for this.
      - Unless you have followed the Harbor setup steps, you don't have these at this time. Just put a placeholder for now, and fill them in later.
    - Run the `gen-regcred.sh` script.
  - Cloudflare

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
- This API Key must be supplied to `traefik/cloudflare.env`, along with the email you are using.
  - Rename `cloudflare.env.template` to `cloudflare.env`.
- If all is setup correctly, you should now be able to access subdomains `registry`, `argocd`, `nexus` and `jenkins` when connected to tailscale, with proper letsencrypt TLS certs (created with DNS-01 challenge).


### Configure Secrets
- Using the `kubeseal` client, re-generate the public certificate for your cluster by running `secret/gen-pub.sh`
- Run the secret generation scripts:
  - Jenkins registry credentials:
    - Rename `jenkins/dockerconfig.json.template` to `jenkins/dockerconfig.json` and fill in credentials for this.
      - Unless you have followed the Harbor setup steps, you don't have these at this time. Just put a placeholder for now, and fill them in later.
    - Run the `jenkins/gen-regcred.sh` script.
  - Cloudflare DNS-01 Challenge:
    - You should have already written credentials in the previous step to `traefik/cloudflare.env`
    - Run the `traefik/gen-cloudflare.sh` script.
  - Velocity Cluster-Wide Forwarding Secret:
    - Create a file `realm/forwarding.secret` and put a plaintext secret for velocity forwarding
    - Run the `realm/gen-velocity-forwarding.sh` script.

### Deploy
- Run the `apply.sh` script.
- You are now ready to start configuring the cluster services.
## Configuration

### Passwords
- Modify the harbor password at `registry.runicrealms.com` from the default
- Get and modify the argocd default admin password at `argocd.runicrealms.com` from the default
- Create a jenkins user at `jenkins.runicrealms.com`

### Harbor
- Login to `registry.runicrealms.com`, create a project named `build` and a project named `jenkins`. There should also be a default one called `library`.
  - These should all be public projects
- Create a robot user named `jenkins` (will be named `robot$jenkins`) with permission to read/modify all repositories in projects `build`, `jenkins` and `library`
  - At this stage you need to go back and update the `regcred` secret you installed in the `jenkins` namespace with this robot password.

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
- Names: `Realm-Velocity`, `Realm-Paper`, `Velagones`, `Trove`
- SCMs:
  - `git@github.com:Runic-Studios/Realm-Velocity.git`
  - `git@github.com:Runic-Studios/Realm-Paper.git`
  - `git@github.com:Runic-Studios/Velagones.git`
  - `git@github.com:Runic-Studios/Trove.git`
  - `git@github.com:Runic-Studios/Palimpsest.git`
  - `git@github.com:Runic-Studios/RR-Game.git`
  - `git@github.com:Runic-Studios/RR-Writer.git`
- Branches filter by expression `dev|main`
- Discard old items after 7 days

Modify SCM settings:
- This is highly recommended to do for Realm-Paper and Realm-Velocity since they have large commit histories, but can be done for other build jobs as well:
  - Branch Sources -> Git -> Add Behaviours
    - Advanced clone behaviours:
      - Disable fetch tags
      - Enable honour refspec on initial clone
      - Enable shallow clone with depth 1

## Development Steps

These are the steps required in order for you to not only deploy the Realm, but to develop code, run build jobs, enable CD, etc.

### Install
- Install docker cli
- Install oras cli

### Add Jenkins Agents
These must be built and pushed to the harbor register in order for Jenkins to be able to build anything.

- Clone `git@github.com:Runic-Studios/Jenkins-Shared-Lib.git`
  - Run `docker login -u admin https://registry.runicrealms.com` and enter your docker password
  - Run `agents/push.sh`
  - You may want to clean up after using `Deploy/cleanup.sh`, which removes all docker images

### Populate Harbor Registry
- Build dev branches of Jenkins items in this order:
  - Palimpsest
  - Trove
  - Velagones
  - Realm-Paper
  - Realm-Velocity
  - RR-Game
  - RR-Writer

### Upload world artifacts
- Download the `worlds.zip` file from an RR developer.
- Put this file inside `realm`
- Run `realm/push-worlds.sh REGISTRY_USERNAME REGISTRY_PASSOWRD`

### Add Base Images
- Clone `git@github.com:Runic-Studios/Realm-Paper-Base.git` and `git@github.com:Runic-Studios/Realm-Paper-Base.git`
  - For both, run `./push.sh` (you must have oras installed)

