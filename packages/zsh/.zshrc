# Enable vi mode
bindkey -v

# Navigation
setopt auto_cd

# Source

for aliasfile in ~/.aliases/*; do
  if [ -f "$aliasfile" ]; then
    source "$aliasfile"
  fi
done

for functionfile in ~/.functions/*; do
  if [ -f "$functionfile" ]; then
    source "$functionfile"
  fi
done

# .zshrc
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

source ~/.zsh/plugins.zsh
source ~/.zsh/history.zsh
source ~/.zsh/completion.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Added by me
export CHROME_PATH="/usr/bin/google-chrome-stable"
export PATH=$PATH:$CHROME_PATH
export PATH=/home/aram/.cache/yay/bcompare/src/install/bin:$PATH
export PATH=$PATH:/home/aram/devel/gradle-5.2.1/bin
export PATH=$PATH:/home/aram/devel/apache-maven-3.6.1/bin
alias rmorig='find . -name '"'"'*.orig'"'"' -delete'
alias say='fortune | cowsay -f $(ls /usr/share/cows/ | shuf -n 1)'
alias bee='fortune | cowsay -f ~/devel/cowsay/cows/sodomized-sheep.cow'
alias docs-to-pdf='sh ~/devel/docs-to-pdf-converter/docs-to-pdf-converter.sh'
say
