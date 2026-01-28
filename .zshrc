# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/vic/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Agregar ~/.local/bin al PATH
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ls="eza --group-directories-first"

# Inicializar Starship
eval "$(starship init zsh)"

export LS_COLORS="$(vivid generate one-dark)"
export EDITOR=nvim
export VISUAL=nvim
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
