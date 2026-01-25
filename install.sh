#!/usr/bin/env bash

set -e

dotfiles_dir="$HOME"/dotfiles

# Link dotfiles
mkdir -p "$HOME"/.config
mkdir -p ~/.local/bin
rm -rf "$HOME"/.{zshrc,zprofile,profile,bashrc,bash_logout}
ln -sf $dotfiles_dir/.zshenv $HOME/.zshenv
ln -sf $dotfiles_dir/.gitignore.global $HOME/.gitignore.global
ln -sf $dotfiles_dir/.gitconfig $HOME/.gitconfig
ln -sf $dotfiles_dir/.gitattributes $HOME/.gitattributes
ln -sf $dotfiles_dir/.agignore $HOME/.agignore
cp -a "$dotfiles_dir/.config/zsh" "$HOME/.config/zsh"


export XDG_CONFIG_HOME="$HOME/.config/"

# Install tmux
echo "Installing tmux..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y tmux
elif command -v apk >/dev/null 2>&1; then
    sudo apk add tmux
fi

# Set ZDOTDIR if zsh config directory exists
if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh/"
fi

# Add environment variables to /etc/zprofile
echo "Adding environment variables to /etc/zprofile..."
cat << EOF | sudo tee -a /etc/zprofile > /dev/null

if [[ -z "\$XDG_CONFIG_HOME" ]]
then
        export XDG_CONFIG_HOME="\$HOME/.config/"
fi

if [[ -d "\$XDG_CONFIG_HOME/zsh" ]]
then
        export ZDOTDIR="\$XDG_CONFIG_HOME/zsh/"
fi
EOF

setup_pnpm() {
    if [[ -n "$PNPM_ENV_INITIALIZED" ]]; then
        return
    fi

    SHELL=zsh pnpm setup

    export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac

    PNPM_ENV_INITIALIZED=1
}

echo "Installing claude code..."
if command -v pnpm >/dev/null 2>&1; then
    setup_pnpm
    pnpm install -g @anthropic-ai/claude-code
fi

echo "Installing codex..."
if command -v pnpm >/dev/null 2>&1; then
    setup_pnpm
    pnpm install -g @openai/codex
fi

echo "Installing gemini-cli..."
if command -v pnpm >/dev/null 2>&1; then
    setup_pnpm
    pnpm install -g @google/gemini-cli
fi

echo "Installing Axiom CLI..."
if ! command -v axiom >/dev/null 2>&1; then
    AXIOM_VERSION="0.14.7"
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) AXIOM_ARCH="amd64" ;;
        aarch64|arm64) AXIOM_ARCH="arm64" ;;
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    AXIOM_URL="https://github.com/axiomhq/cli/releases/download/v${AXIOM_VERSION}/axiom_${AXIOM_VERSION}_linux_${AXIOM_ARCH}.tar.gz"

    curl -L "$AXIOM_URL" -o /tmp/axiom.tar.gz
    tar -xzf /tmp/axiom.tar.gz -C /tmp
    mv /tmp/axiom_${AXIOM_VERSION}_linux_${AXIOM_ARCH}/axiom ~/.local/bin/axiom
    chmod +x ~/.local/bin/axiom
    rm -rf /tmp/axiom.tar.gz /tmp/axiom_${AXIOM_VERSION}_linux_${AXIOM_ARCH}

    echo "Axiom CLI ${AXIOM_VERSION} installed successfully"
fi

if command -v vim >/dev/null 2>&1; then
    echo "Installing vim configuration..."
    curl https://raw.githubusercontent.com/e7h4n/e7h4n-vim/master/bootstrap.sh -L -o - | sh
    echo "vim configuration installation completed"
fi

# Install zimfw (zsh framework)
echo "Installing zimfw..."
rm -rf ${ZDOTDIR:-${HOME}}/.zim
git clone --recursive https://github.com/zimfw/zimfw.git ${ZDOTDIR:-${HOME}}/.zim

echo "Initializing zimfw..."
zsh -c "source ${ZDOTDIR:-${HOME}}/.zim/zimfw.zsh init -q"

echo "zimfw installation completed"

echo "All setup completed successfully!"
