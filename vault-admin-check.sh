#!/bin/bash

# Set Vault Address
export VAULT_ADDR=http://102.37.142.227:8200

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Check if Vault is running
echo -e "${GREEN}🔍 Checking Vault systemd service...${NC}"
sudo systemctl start vault
sudo systemctl status vault --no-pager

# Wait a bit to make sure Vault is up
sleep 2

# Check Vault seal status
echo -e "\n${GREEN}🔐 Checking if Vault is sealed...${NC}"
sealed=$(vault status -format=json | jq -r '.sealed')

if [ "$sealed" = "true" ]; then
  echo -e "${GREEN}Vault is sealed. Please enter 3 unseal keys:${NC}"
  for i in 1 2 3; do
    echo -n "Enter Unseal Key $i: "
    read -s key
    echo
    vault operator unseal "$key"
  done
else
  echo -e "${GREEN}Vault is already unsealed.${NC}"
fi

# Login with token
echo -e "\n${GREEN}🔑 Logging in...${NC}"
echo -n "Enter Root/Admin Token: "
read -s VAULT_TOKEN
export VAULT_TOKEN
echo

vault token lookup > /dev/null
if [ $? -ne 0 ]; then
  echo -e "❌ Invalid token. Exiting."
  exit 1
fi
echo -e "${GREEN}✅ Token valid.${NC}"

# Check student AppRole
echo -e "\n${GREEN}📎 Checking student-role AppRole...${NC}"
vault read auth/approle/role/student-role || echo "❌ student-role not found"

# Check student secret
echo -e "\n${GREEN}🔎 Checking student01 secret...${NC}"
vault kv get secret/student01 || echo "❌ secret/student01 not found"

echo -e "\n${GREEN}🚀 Vault admin check complete.${NC}"
