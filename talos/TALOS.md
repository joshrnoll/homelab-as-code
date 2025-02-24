## Talos Configuration
Before doing anything, it is recommended to add the following to your ```~/.bashrc``` file:

```
export TALOSCONFIG=./talosconfig
```
This eliminates the need to add ```--talosconfig=./talosconfig``` to the end of every ```talosctl``` command.

### 1. Generate config files for:

The following was used to generate the ```controlplane.yaml```, ```worker.yaml``` and ```talosconfig``` files. ***Run both commands from repo root directory***

#### Staging:

```
cd talos/staging && talosctl gen config staging https://talos-staging:6443 --install-image=factory.talos.dev/installer/58e4656b31857557c8bad0585e1b2ee53f7446f4218f3fae486aa26d4f6470d8:v1.9.4
```

The following was added to staging to allow for a single-node cluster:

```YAML
cluster:
    allowSchedulingOnControlPlanes: true
```

#### Production:
```
cd talos/prod && talosctl gen config production https://10.0.30.80:6443 --install-image=factory.talos.dev/installer/58e4656b31857557c8bad0585e1b2ee53f7446f4218f3fae486aa26d4f6470d8:v1.9.4
```
The production cluster must be use the first controlplane node's IP as the endpoint until after being bootstrapped. Once bootstrapped, the endpoint should be ***changed to the VIP*** in both ```controlplane.yaml``` and ```worker.yaml```

Therefore, the ```cluster:``` section will initially look like this:

```YAML
cluster:
    id: <super-secret> # Globally unique identifier for this cluster (base64 encoded random 32 bytes).
    secret: <super-secret> # Shared secret of cluster (base64 encoded random 32 bytes).
    # Provides control plane specific configuration options.
    controlPlane:
        endpoint: https://10.0.30.80:6443 # Static IP of first node -- will be changed later to VIP
    clusterName: production # Configures the cluster's name.
```

### 2. Encrypt Secrets
The following was used to encrypt the secrets within the files using [sops and age](https://github.com/getsops/sops?tab=readme-ov-file#encrypting-using-age):

**worker.yaml** & **controlplane.yaml** 
```
# Replace worker.yaml and worker.enc.yaml with desired input/output filenames
sops encrypt --age <age-public-key-string> --encrypted-regex '^(crt|key|token|id|secret|secretboxEncryptionSecret)$' worker.yaml > worker.enc.yaml
```

The **talosconfig** file was encrypted entirely with:

```
sops encrypt --age <age-public-key-string> talosconfig > talosconfig.enc.yaml
```

Unencrypted files are gitignored.

### 3. Decrypt Secrets

When cloning the repo for the first time it will be necessary to decrypt the secrets. Example:
```
sops decrypt worker.enc.yaml > worker.yaml
```
All config files should be gitignored, but ***double check!***

### 4. Apply Control Plane Config and Machine Patches to First Node
On the first node it is necessary to use the ```--insecure``` flag. Note that you will also need to use the IP received from the DHCP server on this first command rather than the IP configured in the machine's patch file.

```
talosctl apply-config --insecure -f controlplane.yaml -n 10.0.30.168 -e 10.0.30.168 --config-patch @nodes/talos-staging.patch.yaml --config-patch @tailscale.patch.yaml
```

### 5. Bootstrap Kubernetes and Retrieve Kubeconfig

To bootstrap Kubernetes:
```
talosctl bootstrap -n 10.0.30.80 -e 10.0.30.80
```
***This is only done one time!***

For the production cluster -- ensure the following is changed in both ```controlplane.yaml``` and ```worker.yaml``` before retrieving the kubeconfig:

```YAML
cluster:
    id: <super-secret> # Globally unique identifier for this cluster (base64 encoded random 32 bytes).
    secret: <super-secret> # Shared secret of cluster (base64 encoded random 32 bytes).
    # Provides control plane specific configuration options.
    controlPlane:
        endpoint: https://10.0.30.25:6443 # Change this to the VIP!!
    clusterName: production # Configures the cluster's name.
```

Then, reapply the configs (omit the ```--insecure``` flag):

```
talosctl apply-config -f controlplane.yaml -n 10.0.30.80 -e 10.0.30.80 --config-patch @nodes/talos-staging.patch.yaml --config-patch @tailscale.patch.yaml
```
Finally, retrieve the kubeconfig with:

```
talosctl kubeconfig -n 10.0.30.80 -e 10.0.30.80
```
> **Note:** You'll *never use the VIP* when running ```talosctl```! Always use a controlplane node's static IP.

### 6. Apply Control Plane and Worker Configs/Patches to Remaining Nodes
Now, apply the config to any remaining control plane and worker nodes to add them to the cluster:

For control plane:
```
talosctl apply-config -f controlplane.yaml -n <ip-of-node> -e <ip-of-node> --config-patch @nodes/talos-staging.patch.yaml --config-patch @tailscale.patch.yaml
```

For workers:
```
talosctl apply-config -f worker.yaml -n <ip-of-node> -e <ip-of-node> --config-patch @nodes/talos-staging.patch.yaml --config-patch @tailscale.patch.yaml
```

> **Note:** These commands may be ran many times. Any time a config or patch is modified, it will be necessary to run these commands against all nodes.