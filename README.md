# Set up Vault Server and App Role


This set up the vault server and enabled the app role. Others can connect to vault by exporting vaultcred such as:

export VAULT_ADDR="http://<your-vm-ip>:8200"
export VAULT_ROLE_ID="xxxxxxx-xxxxx"
export VAULT_SECRET_ID="yyyyyyy-yyyyy"


## 1. Install Vault on Ubuntu
```
sudo apt update && sudo apt install -y wget unzip

# Download Vault 1.19.3
wget https://releases.hashicorp.com/vault/1.19.3/vault_1.19.3_linux_amd64.zip
unzip vault_1.19.3_linux_amd64.zip
sudo mv vault /usr/local/bin/

# Verify installation
vault --version

```

## 2. Create Vault User and Directories
```
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
sudo mkdir -p /etc/vault.d /var/lib/vault
sudo chown -R vault:vault /etc/vault.d /var/lib/vault

```

## 3. Configure Vault 

nano `/etc/vault.d/vault.hcl` and paste below

```
storage "file" {
  path = "/var/lib/vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

ui            = true
disable_mlock = true

sudo chown vault:vault /etc/vault.d/vault.hcl
```

## 4. Create and Enable Vault as a Systemd Service

Create `/etc/systemd/system/vault.service`:
```
[Unit]
Description=HashiCorp Vault
After=network-online.target
Requires=network-online.target

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

## Start the service:
```
sudo systemctl daemon-reexec
sudo systemctl enable vault
sudo systemctl start vault
```

## 5. Export Vault Environment Variables

` export VAULT_ADDR='http://127.0.0.1:8200' `

or  Make it permanent:

```
echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
source ~/.bashrc
```
## 6 Initialize and Unseal Vault
vault operator init


### Save: 5 unseal keys and 1 root token.

Unseal Vault with 3 of the keys:

vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>


Login as root:

vault login <root_token>

## 7. Enable KV v2 Secrets Engine
```
vault secrets enable -path=secret kv-v2

Verify:

vault secrets list -detailed
```
## 8. Store MongoDB URI Secret
`vault kv put secret/student01 MONGO_URI="mongodb+srv://user:pass@cluster.mongodb.net/"`


### Test:

vault kv get secret/student01

## Create Access Policy (read-student01.hcl)
```
path "secret/data/student01" {
  capabilities = ["read"]
}

path "secret/metadata/student01" {
  capabilities = ["read"]
}
```

Save as read-student01.hcl and load it:

vault policy write read-student01 read-student01.hcl

## 10. Set Up AppRole for Students

Enable AppRole if not already:

vault auth enable approle


### Create role:
```
vault write auth/approle/role/student01 \
    token_policies="read-student01" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h
```

### Fetch credentials:

```
vault read auth/approle/role/student01/role-id
vault write -f auth/approle/role/student01/secret-id
```


Get your Secret and Role  use - `vault auth list`

## Manage-Hosted-Vault-Server
you can handle daily login and unseal using the vault-admin-check.sh
