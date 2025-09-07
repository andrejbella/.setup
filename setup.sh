#!/usr/bin/env bash

CURRENT_DIR="$(dirname "$0")"
ZINIT_HOME="${XDG_CACHE_HOME:-${HOME}/.local/share}/zinit/zinit.git"
FZF_HOME="${HOME}/.fzf"

CONFIG_DIR="$HOME/.setup"
ENV_FILE="$CONFIG_DIR/.setup_env"

info()
{
	echo '[INFO] ' "$@"
}

if [[ -f "$ENV_FILE" ]]; then
  echo "Environment already set to $(cat $ENV_FILE)"
else
  echo "Which environment is this machine?"
  echo "1) personal"
  echo "2) work"
  echo "3) other"
  read -rp "Enter number [1-3]: " choice

  case $choice in
    1) ENV="personal" ;;
    2) ENV="work" ;;
    3) read -rp "Enter custom env name: " ENV ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac

  echo "$ENV" > "$ENV_FILE"
  echo "Environment set to $ENV"
fi

echo
info "Installing tools"
sudo apt update -y && sudo apt install \
	ssh \
	zsh \
	git \
	curl \
	zoxide \
	btop \
	eza \
	micro \
	gcc \
	jq \
	jwt \
	tcpdump \
	net-tools \
	wslu \
	tmux \
	keychain \
	build-essential \
	dnsutils \
	etcd-client \
	-y

echo
info "Installing zinit"
if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

info "Installing Homebrew"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
/home/linuxbrew/.linuxbrew/bin/brew analytics off

info "Installing brew tools"
/home/linuxbrew/.linuxbrew/bin/brew tap hashicorp/tap
/home/linuxbrew/.linuxbrew/bin/brew install \
	talosctl \
	fzf \
	derailed/k9s/k9s \
	hashicorp/tap/terraform \
	fluxcd/tap/flux \
	kubecolor \
	kubectx \
	asdf \
	clusterawsadm \
	kubelogin \
	yq

###P10K###
P10K_DIR="$CURRENT_DIR/powerlevel10k"
THEME_DIR="$CURRENT_DIR/themes"
if [ ! -d "$THEME_DIR" ]; then
	mkdir -p "$THEME_DIR"
fi
sudo rm -rf "$THEME_DIR/powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR/powerlevel10k"
cp -f "$CURRENT_DIR/p10k.zsh" "$HOME/.p10k.zsh"

echo
info "tmux kube context"
rm -rf "$HOME/.tmux"
mkdir -p "$HOME/.tmux"
git clone https://github.com/jonmosco/kube-tmux.git "$HOME/.tmux/kube-tmux"

echo
info "Copying .tmux.conf to ~/"
cp -f "$CURRENT_DIR/tmux.conf" "$HOME/.tmux.conf"

if [[ "$ENV" == "work" ]]; then
	echo
	info "Copying .zshrc to ~/"
	cp -f "$CURRENT_DIR/$ENV/zshrc.work" "$HOME/.zshrc"

	echo
	info "Copying .gitconfig to ~/"
	cp -f "$CURRENT_DIR/$ENV/gitconfig.work" "$HOME/.gitconfig"
elif [[ "$ENV" == "personal" ]]; then
  	echo
	info "Copying .zshrc to ~/"
	cp -f "$CURRENT_DIR/base/zshrc" "$HOME/.zshrc"

	echo
	info "Copying .gitconfig to ~/"
	cp -f "$CURRENT_DIR/base/gitconfig" "$HOME/.gitconfig"
fi

# echo
# info "Installing krew"
# 
# (
#   set -x; cd "$(mktemp -d)" &&
#   OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
#   ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
#   KREW="krew-${OS}_${ARCH}" &&
#   curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
#   tar zxvf "${KREW}.tar.gz" &&
#   ./"${KREW}" install krew
# )

echo
info "Installing azure-cli"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo
info "Installing asdf plugins"
asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git
asdf plugin add clusterctl https://github.com/pfnet-research/asdf-clusterctl.git
asdf plugin add awscli https://github.com/MetricMike/asdf-awscli.git

echo
info """
Done. Next step is to:
Install the JetBrains Mono Nerd font at https://www.nerdfonts.com/font-downloads
Change the wsl theme from wsl.conf
Apply shortcuts from wsl.conf
"""

chsh -s $(which zsh)

