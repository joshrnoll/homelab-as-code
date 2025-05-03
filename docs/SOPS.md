# Using SOPS to Encrypt and Decrypt Files

This repository uses [SOPS (Secrets OPerationS)](https://github.com/mozilla/sops) to manage encrypted files. SOPS allows you to securely encrypt and decrypt sensitive data, such as configuration files or secrets, using a variety of encryption backends (e.g., AWS KMS, GCP KMS, Azure Key Vault, or PGP). [Age](https://github.com/FiloSottile/age) is the encryption backend of choice in this case. 

## Prerequisites

1. Install SOPS:
    - Follow the installation instructions for your platform: https://github.com/mozilla/sops#installation

2. install age:
    - Follow the installation instructions for your platform: https://github.com/FiloSottile/age#installation

3. Generate an age key:

```
age-keygen -o key.txt
```
4. Save the age private key to a Kubernetes secret in the flux-system namespace:

```YAML
---
apiVersion: v1
kind: Secret
metadata:
  name: sops-key
  namespace: flux-system
data:
  identity.agekey: <age-private-key>
```
Replace `<age-private-key>` with your private key. Save the above YAML to a file such as ```age-key.yaml``` and apply it to the cluster with ```kubectl apply -f age-key.yaml```. ***Ensure this file is gitignored!***

## Configuring SOPS
A configuration file can be used to reduce the amount of command-line flags required when encrypting a file. There may be multiple configuration files throughout a repo. SOPS will use the *one closest to your current working directory* unless otherwise specified.

In a file named ```.sops.yaml```, add the following:

```YAML
creation_rules:
  - path_regex: .*.yaml
    age: <age-public-key>
```

The above example is used to encrypt all ```.yaml``` files in their entirety.

To specify key-value pairs to be encrypted, use the ```encrypted_regex``` field:

```YAML
creation_rules:
  - path_regex: .*.yaml
    encrypted_regex: ^(data|stringData)$
    age: <age-public-key>
```

The above example would encrypt all ```stringData``` values, but leave all keys (and all other key-value pairs) in plain text. This could be used in a directory where you store Kubernetes secrets within the repo. 

## Encrypting a File

To encrypt a file using SOPS:

1. Create or edit the plaintext file you want to encrypt.
2. Run the following command to encrypt the file:
    ```bash
    sops encrypt --in-place <plaintext-file>
    ```
    Replace `<plaintext-file>` with the name of the plaintext file. The file will be encrypted in place according to the configuration in the ```.sops.yaml``` file.

3. Verify the plaintext file has been overwritten with the encrypted version. Commit the encrypted file to the repository. Do not commit the plaintext file.

## Decrypting a File

To decrypt a file encrypted with SOPS:

1. Run the following command:
    ```bash
    sops decrypt --in-place <encrypted-file>
    ```
    Replace `<encrypted-file>` with the name of the plaintext file. The file will be decrypted in place according to the configuration in the ```.sops.yaml``` file.

## Editing an Encrypted File

To edit an encrypted file while keeping it encrypted:

1. Run the following command:
    ```bash
    sops <encrypted-file>
    ```
    This will open the file in your default text editor in its decrypted form. Upon saving and exiting, SOPS will re-encrypt the file automatically.

## Best Practices

- **Do not commit plaintext secrets** to the repository.
- **Verify encryption** before committing changes by running:
  ```bash
  sops --decrypt <encrypted-file>
  ```
  This will output the decrypted contents of the file to stdout. If you receive an error, the file was not encrypted properly.
- Use version control to track changes to encrypted files, but ensure sensitive data remains encrypted.

For more details, refer to the [SOPS documentation](https://github.com/mozilla/sops#usage).