#!/bin/bash
set -e

# SSH host keys aanmaken als ze nog niet bestaan
ssh-keygen -A

# Wachtwoord instellen voor SSH login (vanuit env var)
if [ -n "$SSH_PASSWORD" ]; then
    echo "claude:${SSH_PASSWORD}" | chpasswd
    echo "[entrypoint] SSH wachtwoord ingesteld voor gebruiker 'claude'"
fi

# Publieke SSH sleutel toevoegen (vanuit env var)
if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "$SSH_PUBLIC_KEY" >> /home/claude/.ssh/authorized_keys
    chmod 600 /home/claude/.ssh/authorized_keys
    chown claude:claude /home/claude/.ssh/authorized_keys
    echo "[entrypoint] SSH publieke sleutel toegevoegd"
fi

# Git globale configuratie
if [ -n "$GIT_USER_NAME" ]; then
    su - claude -c "git config --global user.name '${GIT_USER_NAME}'"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    su - claude -c "git config --global user.email '${GIT_USER_EMAIL}'"
fi

# Tailscale opstarten als auth key aanwezig is
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "[entrypoint] Tailscale starten..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state &
    sleep 2
    tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="${TAILSCALE_HOSTNAME:-claude-docker}"
    echo "[entrypoint] Tailscale verbonden"
fi

# SSH daemon starten
echo "[entrypoint] SSH server starten op poort 22..."
/usr/sbin/sshd -D
