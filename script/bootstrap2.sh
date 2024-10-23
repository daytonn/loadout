#!/usr/bin/env bash

sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt upgrade -y
sudo apt install git xclip gnome-tweaks build-essential curl terminator dconf-editor gimp inkscape kicad peek rhythmbox vlc zeal
curl -f https://zed.dev/install.sh | sh
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
. "$HOME/.asdf/asdf.sh"
asdf plugin add ruby
asdf install ruby 3.3.4
asdf global ruby 3.3.4
ruby --version
gem install awesome_print

if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
  echo "No public key found, do you want to generate one now?: (Y/n)"
  read -rn1 answer

  if [[ -z "$answer" ]] || [[ "$answer" =~ [Yy] ]]; then
    echo "Enter the email address you wish to associate with this public key"
    read -r email
    echo "ssh-keygen -t rsa -b 4096 -c \"$email\""
    ssh-keygen -t rsa -b 4096 -c "$email"
  else
    echo "--> Skipping ssh-keygen..."
  fi
fi

if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
  xclip -selection clipboard < "$HOME/.ssh/id_rsa.pub"

  echo -e "id_rsa.pub copied copied to clipboard, add it to your github settings at \nhttps://github.com/settings/keys"
  read -p "Did you add your key to Github and are you ready to continue?: (Y/n) " -n 1 -r
  echo

  if [[ $REPLY = "" ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Bootstrap complete! Do you want to kill this terminal: (Y/n)"
    read -rn1 anwer
    if [[ "$answer" =~ [Yy] ]]; then
      exit 0
    fi
  else
    echo
    echo "Aborting bootstrap..."
  fi
fi
