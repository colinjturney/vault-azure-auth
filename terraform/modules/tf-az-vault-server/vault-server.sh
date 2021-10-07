#!/bin/bash

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update && sudo apt-get install vault

sudo apt-get install unzip

wget -O vault.zip https://releases.hashicorp.com/vault/1.7.5-rc+ent/vault_1.7.5-rc+ent_linux_amd64.zip

unzip vault.zip

rm vault.zip

sudo mv vault /usr/bin/vault

cat << EOF > /etc/vault.d/vault.hcl
ui = true

#mlock = true
#disable_mlock = true

storage "file" {
  path = "/opt/vault/data"
}

# HTTP listener
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

log_level = "Trace"

EOF

sudo service vault start

cat << 'EOF' > /home/azureuser/0-init-vault.sh

# Initialise Vault. Store keys locally FOR DEMO PURPOSES ONLY

export VAULT_ADDR=http://127.0.0.1:8200

vault operator init -key-shares=1 -key-threshold=1 > init-output.txt 2>&1

echo "Unseal: "$(grep Unseal init-output.txt | cut -d' ' -f4) >> vault.txt
echo "Token: "$(grep Token init-output.txt | cut -d' ' -f4) >> vault.txt
rm init-output.txt

# Unseal Vault
vault operator unseal $(cat vault.txt | grep Unseal | cut -f2 -d' ')

# Login to Vault
vault login $(cat vault.txt | grep Token | cut -f2 -d' ')
EOF

cat << 'EOF' > /home/azureuser/1-configure-azure-auth.sh

export VAULT_ADDR=http://127.0.0.1:8200

export TENANT_ID=${tenant_id}

echo "TENANT_ID: $${TENANT_ID}"

vault login $(cat vault.txt | grep Token | cut -f2 -d' ')

vault auth enable azure

vault write auth/azure/config \
  tenant_id="$${TENANT_ID}" \
  resource="https://management.azure.com"

EOF

cat << 'EOF' > /home/azureuser/2-configure-azure-role.sh

export VAULT_ADDR=http://127.0.0.1:8200

vault login $(cat vault.txt | grep Token | cut -f2 -d' ')

vault secrets enable -path=secret/ kv

vault kv put secret/hello value=world

# Create a policy file, vault-client-policy.hcl
tee vault-client-policy.hcl <<EOL
path "secret/*" {
    capabilities = ["read", "list"]
}
EOL

# Create a policy named myapp-kv-ro
vault policy write vault-client-policy vault-client-policy.hcl

vault write auth/azure/role/vault-client \
  policies="vault-client-policy" \
  bound_subscription_ids="" \
  bound_resource_groups="${resource_group}"

EOF

sudo chmod u+x /home/azureuser/{0,1,2}*.sh

sudo chown azureuser:azureuser /home/azureuser/{0,1,2}*.sh