alias antlr4='java -jar ~/antlr/antlr-4.13.1-complete.jar'
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
alias antlr4='java -jar ~/antlr/antlr-4.13.1-complete.jar'

. "$HOME/.local/bin/env"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export SSL_CERT_FILE=$(python -m certifi)
export REQUESTS_CA_BUNDLE=$(python -m certifi)

alias l="eza -lh --sort=Name --group-directories-first --no-permissions --no-user"
alias lt="eza -T --group-directories-first"
alias cd=z
alias n=nvim
alias c=clear
alias k=kubectl
alias g=lazygit
alias d=lazydocker
alias t=btop

# Enabling VI mode for command line editing
set -o vi

# Starship - better prompt styling
eval "$(starship init zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Use TMUX by default for SSH sessions
# Only run if in an interactive shell, NOT already in tmux, and over SSH
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_TTY" ]]; then
    tmux attach-session -t remote_sync || tmux new-session -s remote_sync
fi

# shellcheck shell=bash

# zoxide
eval "$(zoxide init zsh)"
