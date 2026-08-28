#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZINIT_HOME="${XDG_CACHE_HOME:-${HOME}/.local/share}/zinit/zinit.git"
ENV_FILE="$CURRENT_DIR/.setup_env"

info()
{
	echo '[INFO] ' "$@"
}

detect_os()
{
	case "$(uname -s)" in
		Darwin)
			OS=macos
			;;
		Linux)
			if [[ ! -r /etc/os-release ]]; then
				echo "Unable to determine the Linux distribution."
				exit 1
			fi

			# shellcheck disable=SC1091
			source /etc/os-release
			case "$ID" in
				debian|ubuntu) OS=debian ;;
				*)
					echo "Unsupported Linux distribution: $ID. Supported distributions are Debian and Ubuntu."
					exit 1
					;;
			esac
			;;
		*)
			echo "Unsupported operating system: $(uname -s). Supported operating systems are macOS, Debian, and Ubuntu."
			exit 1
			;;
	esac

	info "Detected $OS"
}

find_brew()
{
	if command -v brew >/dev/null 2>&1; then
		BREW_BIN="$(command -v brew)"
	elif [[ -x /opt/homebrew/bin/brew ]]; then
		BREW_BIN=/opt/homebrew/bin/brew
	elif [[ -x /usr/local/bin/brew ]]; then
		BREW_BIN=/usr/local/bin/brew
	elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
		BREW_BIN=/home/linuxbrew/.linuxbrew/bin/brew
	else
		BREW_BIN=""
	fi
}

install_homebrew()
{
	find_brew
	if [[ -z "$BREW_BIN" ]]; then
		info "Installing Homebrew"
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		find_brew
	fi

	if [[ -z "$BREW_BIN" ]]; then
		echo "Homebrew installation was not found."
		exit 1
	fi

	eval "$("$BREW_BIN" shellenv)"
	"$BREW_BIN" analytics off
}

install_system_tools()
{
	case "$OS" in
		debian)
			info "Installing Debian/Ubuntu tools"
			sudo apt update -y
			sudo apt install -y \
				ssh \
				zsh \
				git \
				curl \
				micro \
				gcc \
				tcpdump \
				net-tools \
				keychain \
				build-essential \
				dnsutils
			;;
		macos)
			install_homebrew
			info "Installing macOS tools"
			"$BREW_BIN" install \
				git \
				curl \
				micro \
				gcc \
				btop \
				eza \
				tcpdump \
				keychain \
				bind \
				inetutils \
				ghostty \
				maccy \
				raycast \
				dockdoor \
				scroll-reverser
			;;
	esac
}

configure_environment()
{
	if [[ -f "$ENV_FILE" ]]; then
		echo "Environment already set to $(cat "$ENV_FILE")"
		return
	fi

	echo "Which environment is this machine?"
	echo "1) personal"
	echo "2) work"
	echo "3) other"
	read -r -p "Enter number [1-3]: " choice

	case "$choice" in
		1) ENV="personal" ;;
		2) ENV="work" ;;
		3) read -r -p "Enter custom env name: " ENV ;;
		*) echo "Invalid choice"; exit 1 ;;
	esac

	echo "$ENV" > "$ENV_FILE"
	echo "Environment set to $ENV"
}

install_zinit()
{
	info "Installing zinit"
	if [[ ! -d "$ZINIT_HOME" ]]; then
		mkdir -p "$(dirname "$ZINIT_HOME")"
		git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
	fi
}

install_brew_tools()
{
	install_homebrew
	info "Installing brew tools"
	"$BREW_BIN" install \
		mise \
		Azure/azure-workload-identity/azwi \
		dgunzy/tap/flux9s \
		kcl-lang/tap/kcl-lsp
}

install_mise_tools()
{
	if [[ -f "$HOME/mise-download-token" ]]; then
		info "Exporting GitHub token for authenticated mise requests"
		export GITHUB_TOKEN="$(cat "$HOME/mise-download-token")"
	fi

	info "Installing mise pipx backend"
	mise use --global pipx

	info "Installing mise tools"
	mise use --global \
		clusterctl \
		kubectl \
		awscli \
		helm \
		kubectx \
		kubens \
		kubecolor \
		talosctl \
		fzf \
		k9s \
		opentofu \
		flux2 \
		clusterawsadm \
		kubelogin \
		yq \
		kustomize \
		stern \
		sops \
		trufflehog \
		kcl \
		task \
		fd \
		ripgrep \
		azure-cli \
		krew \
		zoxide \
		jq \
		jwt \
		age \
		etcd \
		tmux \
		claude

	if [[ "$OS" == "debian" ]]; then
		mise use --global btop eza
	fi
}

install_powerlevel10k()
{
	THEME_DIR="$CURRENT_DIR/themes"
	mkdir -p "$THEME_DIR"
	rm -rf "$THEME_DIR/powerlevel10k"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR/powerlevel10k"
	ln -sf "$CURRENT_DIR/configs/base/p10k.zsh" "$HOME/.p10k.zsh"
}

install_tmux_kube_context()
{
	info "Installing tmux kube context"
	rm -rf "$HOME/.tmux"
	mkdir -p "$HOME/.tmux"
	git clone https://github.com/jonmosco/kube-tmux.git "$HOME/.tmux/kube-tmux"
}

symlink_configs()
{
	info "Symlinking config files"
	ENV="$(cat "$ENV_FILE")"
	ENV_CONFIG_DIR="$CURRENT_DIR/configs/$ENV"

	mkdir -p "$HOME/.config/k9s" "$HOME/.config/micro" "$HOME/.kube/my_configs" "$HOME/.config/ghostty"
	rm -f "$HOME/.zshrc" "$HOME/.gitconfig"
	ln -sf "$CURRENT_DIR/configs/base/zshrc" "$HOME/.zshrc"
	ln -sf "$ENV_CONFIG_DIR/gitconfig" "$HOME/.gitconfig"
	ln -sf "$CURRENT_DIR/configs/base/k9s/config.yaml" "$HOME/.config/k9s/config.yaml"
	ln -sf "$CURRENT_DIR/configs/base/tmux.conf" "$HOME/.tmux.conf"
	ln -sf "$CURRENT_DIR/configs/base/k9s/plugins.yaml" "$HOME/.config/k9s/plugins.yaml"
	ln -sf "$CURRENT_DIR/configs/base/k9s/aliases.yaml" "$HOME/.config/k9s/aliases.yaml"
	ln -sf "$CURRENT_DIR/configs/base/micro/settings.json" "$HOME/.config/micro/settings.json"
	ln -sfn "$CURRENT_DIR/skins/k9s" "$HOME/.config/k9s/skins"
	ln -sfn "$CURRENT_DIR/skins/micro" "$HOME/.config/micro/colorschemes"
	ln -sf "$CURRENT_DIR/configs/base/ghostty/config" "$HOME/.config/ghostty/config"
}

configure_login_shell()
{
	if [[ "$OS" == "macos" ]]; then
		ZSH_PATH=/bin/zsh
	else
		ZSH_PATH="$(command -v zsh)"
	fi

	if [[ "$SHELL" != "$ZSH_PATH" ]]; then
		chsh -s "$ZSH_PATH"
	fi
}

detect_os
configure_environment
install_system_tools
install_zinit
install_brew_tools
install_mise_tools
install_powerlevel10k
install_tmux_kube_context
symlink_configs
configure_login_shell

echo
info "Done. Install the JetBrains Mono Nerd Font from https://www.nerdfonts.com/font-downloads."