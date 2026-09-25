#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [[ -e .env || -L .env ]]; then
    echo '.env уже существует. Измените его вручную; пароли сохранены.' >&2
    exit 1
fi

command -v openssl >/dev/null 2>&1 || {
    echo 'Установите OpenSSL для генерации паролей.' >&2
    exit 1
}

read -r -p 'Домен Nyx (например, nyx.example.com): ' domain
if [[ ${#domain} -gt 253 || ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]; then
    echo 'Укажите домен без протокола, порта и пути.' >&2
    exit 1
fi
IFS=. read -r -a labels <<< "$domain"
for label in "${labels[@]}"; do
    if [[ ${#label} -gt 63 || ! $label =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
        echo 'Некорректная часть домена: используйте до 63 букв, цифр или дефисов, без дефисов по краям.' >&2
        exit 1
    fi
done

umask 077
temp_file=$(mktemp .env.tmp.XXXXXX)
trap 'rm -f -- "$temp_file"' EXIT
trap 'exit 1' HUP INT TERM

while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line == DOMAIN=* ]]; then
        printf 'DOMAIN=%s\n' "$domain"
    elif [[ $line =~ ^[A-Z][A-Z0-9_]*=$ ]]; then
        secret=$(openssl rand -hex 32)
        printf '%s%s\n' "$line" "$secret"
    else
        printf '%s\n' "$line"
    fi
done < .env.example > "$temp_file"

# Publish the completed file atomically; never replace an existing .env.
ln -- "$temp_file" .env
echo 'Создан .env с правами 600. Логин админки: admin, пароль: ADMIN_PASSWORD в .env.'
