# Set XDG_CONFIG_HOME

export XDG_CONFIG_HOME=$HOME/.config

# Modify PATH

if [ -d "/sbin" ]; then
    PATH="/sbin:$PATH"
fi

if [ -d "/usr/sbin" ]; then
    PATH="/usr/sbin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
    PATH=$HOME/bin:$PATH
fi

if [ -d "$HOME/.scripts" ]; then
    PATH=$HOME/.scripts:$PATH
fi

# Merge in defaults

userresources=$HOME/.Xresources

if [ -f "$userresources" ]; then
  xrdb -merge "$userresources"
fi

# Setup keyboard

usermodmap=$HOME/.Xmodmap

setxkbmap \
  -model thinkpadz60 \
  -layout us,am,ru \
  -variant ,phonetic-alt,phonetic \
  -option 'grp:shifts_toggle' \
  -option 'caps:ctrl_modifier'

if [ -f $usermodmap ]; then
   xmodmap $usermodmap
fi

# xcape -e 'Caps_Lock=Escape'
