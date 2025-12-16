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

### Deploy Secret Manager
- Before we can deploy the rest of the cluster, we need the sealed-secrets-controller to be running so that we can populate things.
- Run `cd secret && ../apply.sh && cd ..` to deploy the bitnami secret controller
- Run `secret/gen-pub.sh` to generate the sealed-secret public key, and commit and push that file.
- We are now ready to generate secrets.


### Tailscale and Cloudflare
- The current setup involves a cluster that is completely hidden behind a tailscale VPN.
  - Cloudflare manages DNS resolution and points all subdomains (`registry`, `argocd`, `nexus`) to the k3s node IP in the tailscale network.
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

- Run the secret generation scripts:
  - Cloudflare DNS-01 Challenge:
    - You should have already written credentials in the previous step to `traefik/cloudflare.env`
    - Run the `traefik/gen-cloudflare.sh` script.
  - Velocity Cluster-Wide Forwarding Secret:
    - Create a file `realm/forwarding.secret` and put a plaintext secret for velocity forwarding. Make sure it does not end with a newline!
    - Run the `realm/gen-velocity-forwarding.sh` script.
  - Actions Runner Controller (ARC):
    - Follow the instructions [here](https://docs.github.com/en/actions/tutorials/use-actions-runner-controller/authenticate-to-the-api#authenticating-arc-with-a-github-app) for setting up an actions runner GitHub App.
      - You should note down the App ID, installation ID, and the private RSA key for the app.
    - Rename `arc/gh-app.env.template` to `arc/gh-app.env` and fill in the App ID/installation ID from the instructions.
    - Delete `arc/gh-app.pem.template` and replace it with the downloaded private RSA key for the app.
    - Run `arc/gen-gh-app.sh` to generate the sealed GitHub PAT secrets that our actions runners will use.
      - Note that this generates it twice, once for the `arc-system` namespace and once for the `arc-runners` namespace.
    - Imporant final step: Go to Runic-Studios Organization -> Settings -> Actions -> Runner Groups -> Default, enable "Allow public repositories"

### Deploy
- Run the `apply.sh` script.
  - Note: the first time your run this, you may get errors about CRDs for traefik not being installed yet. Simply run it twice (just for the first time) as this will apply CRDs again.
  - If you get errors about `realm` and `realm-dev` namespaces not existing, ignore these for now since we haven't deployed Realm-Deployment (the argocd managed project for these namespaces) yet.
- Inspect that the resources are healthy using `k9s`.
- You are now ready to start configuring the cluster services.

## Configuration

### Passwords
- Modify the harbor password at `registry.runicrealms.com` from the default
  - You can get the default password using `kubectl -n harbor get secret harbor-core -o jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | base64 --decode`
- Get and modify the argocd default admin password at `argocd.runicrealms.com` from the default
  - You can get the default password using `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- Login and modify the password at `nexus.runicrealms.com
  - You can get the default password using `kubectl exec -n nexus $(kubectl get pod -n nexus -l app.kubernetes.io/name=nexus-repository-manager -o jsonpath='{.items[0].metadata.name}') -- cat /nexus-data/admin.password`

### Harbor
- Login to `registry.runicrealms.com`, create a project named `build` and a project named `agents`. There should also be a default one called `library`.
  - These should all be public projects
- Create a robot user named `actions` (will be named `robot$actions`) with permission to read/modify all repositories in projects `build`, `library` etc.
  - Note down the secret since you will need to set it in the GitHub Organization secrets in a later step.

### Nexus
- Login to `nexus.runicrealms.com`, create an admin password
- Make sure to allow anonymous pulls from nexus

### GitHub Actions and ARC

You must configure the following secrets in your GitHub Organization (or in all repositories):

| Secret Name | Description |
|-------------|-------------|
| `BOT_SSH_KEY` | Private RSA key for `@RunicRealmsGitHub` (for git ops updates) |
| `BOT_PAT` | Personal Access Token for creating PRs |
| `HARBOR_USERNAME` | Harbor robot username (e.g. `robot$actions`) |
| `HARBOR_PASSWORD` | Harbor robot password |
| `NEXUS_USERNAME` | Nexus admin username |
| `NEXUS_PASSWORD` | Nexus admin password |

- Our custom runners come from a single `AutoscalingRunnerSet` that uses label `rr-runner` for all custom jobs.
  - We use Docker-in-Docker (dind) for pulling various "agent" images that have build tools installed already.

## Development Steps

These are the steps required in order for you to not only deploy the Realm, but to develop code, run build jobs, enable CD, etc.

### Install
- Install docker cli
- Install oras cli

### Add Agent Images
We have a set of images that our GitHub runners will use in order to build/deploy code.
- Run `docker login -u admin https://registry.runicrealms.com` and enter your docker password
- Run the `arc/agents/push.sh` script to build and deploy the agent images.
  - This only needs to be done once (unless you update the agent images).

### Add Base Images
- Clone `git@github.com:Runic-Studios/Realm-Paper-Base.git` and `git@github.com:Runic-Studios/Realm-Paper-Base.git`
  - For both, run `./push.sh` (you must have oras installed)

### Populate Harbor Registry
- Run the GitHub action deploy workflow for these repositories in this order:
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
