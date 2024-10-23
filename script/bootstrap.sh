function config {
  local key
  key=".loadout.$1"
  yq e "$key" "$YAML_FILE"
}

YAML_FILE="$HOME/.config/loadout.yml"
LOADOUT_HOME=$(config "home")
LOADOUT_WORKING=$(config "working")
LOADOUT_STORAGE=$(config "storage")
LOADOUT_LINK_COUNT=$(yq e '.loadout.links | length' "$YAML_FILE")
LOADOUT_ENV_COUNT=$(yq e '.loadout.env | length' "$YAML_FILE")
LOADOUT_APP_COUNT=$(yq e '.loadout.apps | length' "$YAML_FILE")

function ensure_id_rsa_file {
  if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
    echo "No public key found, do you want to generate one now?: (Y/n)"
    read -n1 answer
    if [[ -z "$answer" ]] || [[ "$answer" =~ [Yy] ]]; then
      echo "Enter the email address you wish to associate with this public key"
      read email
      echo "ssh-keygen -t rsa -b 4096 -c \"$email\""
      ssh-keygen -t rsa -b 4096 -c "$email"
    else
      echo "<-- Skipping ssh keygen, without keys setup loadout will not work"
    fi
  fi
}

function install_apps {
  for (( i=0; i<LOADOUT_APP_COUNT; i++ )); do
    local app
    local prerequisites_count
    local custom_install
    custom_install=$(config "apps[$i].install")
    prerequisites_count=$(yq e ".loadout.apps[$i].prerequisites | length" "$YAML_FILE")
    app=$(config "apps[$i].name")

    if [[ "$prerequisites_count" != "0" ]]; then
      for (( j=0; j<prerequisites_count; j++ )); do
        step=$(config "apps[$i].prerequisites[$j]")
        echo "--> $step"
      done
    fi

    if [[ "$custom_install" != "null" ]]; then
      echo "--> $custom_install"
      "$custom_install"
    else
      echo "--> sudo apt install -y $app"
      sudo apt install -y "$app"
    fi
    echo ""
  done
}

function bootstrap {
  echo ""
  install_apps
  sudo add-apt-repository ppa:git-core/ppa
  sudo update
  sudo apt install -y git xclip
  ensure_id_rsa_file
  copy_ssh
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
  . "$HOME/.asdf/asdf.sh"
  asdf plugin add ruby
  asdf install ruby 3.3.4

  sudo wget https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64 -O /usr/bin/yq
  sudo chmod +x /usr/bin/yq

  if [[ -n "$1" ]]; then
    if [[ "$1" == "-n" ]]; then
      nuke_environment
    fi

    if [[ "$1" == "-c" ]]; then
      nuke_environment
      link_environment
    fi
  else
    link_environment
  fi

  reload_shell
  echo "--> Bootstrap complete"
}

function copy_ssh {
  if [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
    if [[ -n "$(which xclip)" ]]; then
      cat "$HOME/.ssh/id_rsa.pub" | xclip -selection clipboard
      echo -e "id_rsa.pub copied copied to clipboard, add it to your github settings at \nhttps://github.com/settings/keys"
      read -p "Did you add your key to Github and are you ready to continue?: (Y/n) " -n 1 -r
      echo
      if [[ $REPLY = "" ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Continue bootstrap..."
      else
        echo
        echo "aborting bootstrap..."
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
      fi
    else
      echo "Public ssh file"
      echo ""
      echo -e "Copy the following key and add it to your github settings at \nhttps://github.com/settings/keys:"
      echo ""
      echo "----------BEGIN KEY----------"
      cat "$HOME/.ssh/id_rsa.pub"
      echo "-----------END KEY-----------"
      echo ""
    fi
  fi
}

function storage_dir {
  echo "${LOADOUT_WORKING}/${1}"
}

function src_path {
  local location
  local filename
  location="$1"
  filename="$2"

  if [[ "$location" = "storage" ]]; then
    echo "$LOADOUT_STORAGE/$filename"
  fi

  if [[ "$location" = "working" ]]; then
    echo "$LOADOUT_WORKING/$filename"
  fi
}

function safe_link {
  local src
  local dest
  src="$1"
  dest="$2"
  if [[ -f "$dest" ]] || [[ -d "$dest" ]] || [[ -L "$dest" ]]; then
    echo "--> $dest exists. Skipping..."
  else
    ln -s "$src" "$dest"
    if [[ -d "$dest" ]] || [[ -L "$dest" ]]; then
      echo "--> $dest linked!"
    else
      echo "<-- Error linking $dest!"
    fi
  fi
}

function safe_unlink {
  local dest
  dest="$1"

  if [[ -n "$dest" ]]; then
    if [[ ! -f "$dest" ]]; then
      if [[ -d "$dest" ]]; then
        rm -rf "$dest"
      elif [[ -h "$dest" ]]; then
        unlink "$dest"
      fi

      if [[ ! -L "$dest" ]]; then
        echo "--> $dest removed!"
      else
        echo "<-- Error removing $dest!"
      fi
    fi
  fi
}

function link_environment {
  for (( i=0; i<LOADOUT_LINK_COUNT; i++ )); do
    local location
    local name
    local src
    location=$(config "links[$i].destination")
    name=$(config "links[$i].name")
    src=$(src_path "$location" "$name")
    dest="$LOADOUT_HOME/$name"

    safe_link "$src" "$dest"
  done

  for (( i=0; i<LOADOUT_ENV_COUNT; i++ )); do
    local file
    local src
    local dest
    file=$(config "env[$i]")
    src="$LOADOUT_WORKING/$file"
    dest="$LOADOUT_HOME/$file"

    safe_link "$src" "$dest"
  done
}

function nuke_environment {
  for (( i=0; i<LOADOUT_LINK_COUNT; i++ )); do
    local name
    local src
    name=$(config "links[$i].name")
    dest="$LOADOUT_HOME/$name"

    safe_unlink "$dest"
  done

  for (( i=0; i<LOADOUT_ENV_COUNT; i++ )); do
    local file
    local dest
    file=$(config "env[$i]")
    dest="$LOADOUT_HOME/$file"

    safe_unlink "$dest"
  done
}

function reload_shell {
  echo "--> reload shell"
  exec $SHELL
}

bootstrap
