#!/bin/bash

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update && sudo apt-get install vault

sudo apt-get install unzip

wget -O vault.zip https://releases.hashicorp.com/vault/1.7.5-rc+ent/vault_1.7.5-rc+ent_linux_amd64.zip

unzip vault.zip

rm vault.zip

sudo mv vault /usr/bin/vault

# Replace with a Vault-Agent specific systemd service file for Vault
sudo cat << EOF > /usr/lib/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
EnvironmentFile=/etc/vault.d/vault.env
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=no
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault agent -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/vault.d/vault.hcl

vault {
  address = "http://${vault_server_ip}:8200"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "azure" {
    mount_path = "auth/azure"
    config = {
      role = "vault-client"
      resource = "https://management.azure.com"
    }
  }

  sink "file" {
    config = {
      path = "/tmp/vault-token"
    }
  }
}

template {
  source = "/tmp/template.ctmpl"
  destination = "/tmp/render.txt"
}

EOF

cat << EOF > /tmp/template.ctmpl

  {{with secret "secret/hello" }}
  {{ .Data.value }}
  {{ end }}

EOF

sudo service vault start