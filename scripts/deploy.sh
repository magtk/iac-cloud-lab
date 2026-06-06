#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/6] Sprawdzenie logowania do Azure CLI"
if ! az account show >/dev/null 2>&1; then
  az login
fi

echo "[2/6] Sprawdzenie klucza SSH"
if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
  echo "Brak klucza SSH. Tworze nowa pare kluczy..."
  ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N ""
fi

echo "[3/6] Uruchomienie Terraform"
cd "$ROOT_DIR/terraform"
terraform init
terraform plan
terraform apply -auto-approve

PUBLIC_IP="$(terraform output -raw public_ip_address)"
echo "[4/6] Publiczny adres IP: $PUBLIC_IP"

echo "[5/6] Przygotowanie inventory Ansible"
cd "$ROOT_DIR/ansible"
cp inventory.ini.template inventory.ini
sed -i "s/<PUBLIC_IP>/$PUBLIC_IP/g" inventory.ini

echo "[6/6] Uruchomienie Ansible"
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i inventory.ini playbook.yml

echo
echo "Gotowe. Otworz w przegladarce:"
echo "http://$PUBLIC_IP"
