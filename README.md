![](/homelab-as-code-logo.png)

This repo attempts to bring to life the plans I define in this blog post:

https://joshrnoll.com/my-plan-for-homelab-as-code/

![](/homelab-as-code-workflow.png)

## Overview

On commit, this repo will eventually do the following:

| Feature | Tool | Method | Status |
| :--- | :--- | :--- | :---: |
| Configure/baseline Proxmox nodes  | Ansible | Gitea/GitHub Actions | :construction: |
| Install VM templates on Proxmox nodes  | Ansible | Gitea/GitHub Actions | ❌ |
| Deploy VMs on Proxmox  | Terraform | Gitea/GitHub Actions | ❌ |
| Configure/baseline VMs and other servers | Ansible | Gitea/GitHub Actions | ❌ |
| Deploy Docker workloads | Docker Compose | Portainer GitOps | ❌ |
| Configure/bootstrap Kubernetes nodes | Talos | Gitea/GitHub Actions | 🚧 |
| Deploy Kubernetes workloads | Talos | FluxCD | ✅ |

#### Key
| Icon | Meaning |
| --- | --- | 
| ❌ | Not started |
| 🚧 | In-Progress |
| ✅ | Complete |

### Docs
- [Talos Cluster](/talos/TALOS.md)
- [FluxCD](/clusters/FLUXCD.md)