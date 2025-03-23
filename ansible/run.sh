
#!/bin/bash

# Create SSH private key file
mkdir -p $HOME/.ssh && touch $HOME/.ssh/id_rsa
echo -e "$SSH_PRIVATE_KEY\n" >> $HOME/.ssh/id_rsa
chmod 0700 $HOME/.ssh/id_rsa

# Create Ansible vault password file
echo -n "$ANSIBLE_VAULT_PW" | tr -d '\r' >> $HOME/vault-pw

# Create script for passing the passphrase to ssh-agent
echo '#!/bin/sh' >> passphrase && echo "echo $SSH_PASSPHRASE" >> passphrase
chmod +x passphrase

# Start ssh-agent
eval `ssh-agent -s`
echo -n "$SSH_PRIVATE_KEY" | tr -d '\r' | DISPLAY=1 SSH_ASKPASS="./passphrase" ssh-add -

# Run Ansible playbook
ansible-playbook /workspace/joshrnoll/homelab-as-code/ansible/servers/main.yaml --inventory /workspace/joshrnoll/homelab-as-code/ansible/hosts.yaml --vault-password-file /home/runner/vault-pw --ssh-extra-args "-o StrictHostKeyChecking=no"