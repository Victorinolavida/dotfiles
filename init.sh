
#!/bin/bash
set -e
DIR=$(pwd)
CONFIG_PATH="$HOME/.config/"
FORCE_LINK="force"
KITTY_APP_NAME="kitty"
NVIM_APP_NAME="nvim"

check_app_exist(){
    if ! command -v $1 >/dev/null 2>&1
    then
        echo "$1 could not be found"
        return 1
    fi
    return 0
}

check_file_dir_exist(){
    if ls -d $1 &> /dev/null; then
        return 0
    fi
    return 1
}

create_symbolic_link(){
    local app=$1
    local force=$2
    local command_str="ln -s $DIR/$app $CONFIG_PATH"
    if [[ "$force" == FORCE_LINK ]];then
        local command_str="ln -sf $DIR/$app $CONFIG_PATH"
    fi

    #debug
    # echo $command_str
    eval $command_str

    if [ $? -eq 0 ]; then
      echo "Link created successfully."
        return 0
    else
      echo "Failed to create link."
        return 1
    fi
}

install_kitty_terminal(){
    setup_kitty_configs(){
        echo "Setup kitty..."

        if check_file_dir_exist kitty;
        then
            echo "Configs all ready exist"
            read -p "Override them? " -n 1 -r
            echo    # (optional) move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]];
            then
                create_symbolic_link $KITTY_APP_NAME $FORCE_LINK
            fi
                return 0
        fi

        echo "creating new configs for kitty"
        create_symbolic_link $KITTY_APP_NAME
    }

    if  check_app_exist kitty
    then
        echo "Skip kitty installation"
        setup_kitty_configs
        return 0
    fi
       echo "Installing Kitty terminal"

    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]];
    then
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    fi
        echo "Unknown OS"
        return 1 #throw an error
    ## check if configs are installed
    setup_kitty_configs
}

install_oh_my_ZSH(){
    echo "Installing ohmy zsh"
}

install_nvim(){
    download_and_install_nvim_config(){
       local url="https://github.com/Victorinolavida/minimal_nvim"
       echo "git clone $url $CONFIG_PATH/$NVIM_APP_NAME"
       eval "git clone $url $CONFIG_PATH/$NVIM_APP_NAME"
    }
    if check_app_exist $NVIM_APP_NAME;then
        echo "Neovim installed, skiping"
    else
        echo "Installing neovim"
    fi

    local nvim_path=$CONFIG_PATH/$NVIM_APP_NAME;
    echo $nvim_path

    if check_file_dir_exist $nvim_path;then
        echo "Configs all ready exist"
        read -p "Override them? " -n 0 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]];
        then
            # create_symbolic_link KITTY_APP_NAME FORCE_LINK
            echo "copy and save old Neovim config"
            eval "mv $nvim_path $nvim_path.debug"
            download_and_install_nvim_config
        fi
            return 0
    fi
        download_and_install_nvim_config

}

main(){
    # install Kitty terminal
    install_kitty_terminal && \
    # install zsh and oh my zsh
    install_oh_my_ZSH && \
    ## install neovim
    install_nvim
}

main



