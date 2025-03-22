
# Runic Realms Kustomization Stack
This is the basic set of manifests that should be applied on top of a K3s cluster.

In the future this will be moved to use something like Ansible to ensure declarative configuration.

## Setup Steps

### Installation

- Install K3s with default configuration (should include Traefik!)
- Install K9s, Helm, Kustomize
- Duplicate all files that end in .template (these are secrets that need to be filled in)
- Apply the stack with `kustomize build --enable-helm | kubectl apply -f -`
- Add this to `/etc/rancher/k3s/registries.yaml`:
```yaml
mirrors:
  registry.runicrealms.com:
    endpoint:
      - "http://registry.runicrealms.com"
```
- Add to `/etc/docker/daemon.json`:
```yaml
{
  "debug": true,
  "insecure-registries": ["registry.runicrealms.com"],
}
```

###
 Passwords
- Modify the harbor password at `registry.runicrealms.com` from the default
- Get and modify the argocd default admin password at `argocd.runicrealms.com` from the default
- Create a jenkins user at `jenkins.runicrealms.com`

### Harbor
- Login to `registry.runicrealms.com`, create a project named `build` and a project named `jenkins`
- Create a robot user named `jenkins` (will be named `robot$jenkins`) with permission to read/modify all repositories and `build` and `jenkins`
  - At this stage you need to go back and update the `regcred` secret you installed in the `jenkins` namespace with this robot password

### Jenkins
Install plugins:
- Docker
- Kubernetes for Jenkins
- Git/GitHub

Add Kubernetes Cloud:
- Named `kubernetes`
- Namespace `jenkins`
- Jenkins URL `http://jenkins.jenkins.svc.cluster.local:8080`
- Everything else default/blank

Add credentials:
- GitHub:
  - Git credential type
  - ID `github-ssh`
  - Username `git`
  - Private RSA key you generate, and add to the corresponding GitHub account
  - For us, this account is @RunicRealmsGitHub on GitHub
- Discord: For the discord webhook
  - type: base user/pass
  - ID `discord-webhook`
  - Password is just the discord-generated URL webhook
- Docker registry:
  - Type is basic user/pass
  - Username should be `robot$jenkins`
  - Password is the one generated that harbor gave you
  - ID `docker-registry-credentials`

Add global trusted pipeline library (manage jenkins -> system):
- Named `Jenkins-Shared-Lib`
- Default ref `main`
- Points to modern SCM with https://github.com/Runic-Studios/Jenkins-Shared-Lib
- Uses credentials that we defined earlier

Create multi-branch build configuration: (Realm-Velocity)
- Named `Realm-Velocity`
- SCM `git@github.com:Runic-Studios/Realm-Velocity.git` with our configured credentials
- Branches filter by expression `dev|main`
- Discard old items
