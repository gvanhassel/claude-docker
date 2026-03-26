FROM ubuntu:24.04

ARG USERNAME=claude
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

# System packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    openssh-server \
    sudo \
    ca-certificates \
    gnupg \
    locales \
    tzdata \
    wget \
    vim \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Node.js 22 (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# SSH server setup
RUN mkdir /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# Tailscale (optioneel — alleen actief als TAILSCALE_AUTH_KEY is meegegeven)
RUN curl -fsSL https://tailscale.com/install.sh | sh

# SSH authorized_keys dir voor de gebruiker
RUN mkdir -p /home/$USERNAME/.ssh \
    && chmod 700 /home/$USERNAME/.ssh \
    && chown $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Werkmap
RUN mkdir -p /workspace && chown $USERNAME:$USERNAME /workspace
WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
