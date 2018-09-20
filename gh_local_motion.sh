#!/usr/bin/env bash

# This is my personal private email. You probably want to have your own configuration here.
private_email="43416374+errrrk@users.noreply.github.com"
author="Errrrk"


script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
script_path=$(dirname "$0")
script_name=$(basename -- $0)

source ${script_path}/_utils.sh
source ${script_path}/_ask.sh

ruby::install() {
    if test ! $(which rbenv); then
        info "Installing rbenv..."
        brew install rbenv
        rbenv install 2.5.1
        rbenv global 2.5.1
        echo '$(rbenv init -)' >>$HOME/.bash_profile
    fi

    for gem_name in "$@"
    do
        if [ ! -f /usr/local/bin/${gem_name} ]; then
            gem install ${gem_name}

            if [[ ${gem_name} == "poet" ]]; then
				# Poet uses this directory by default
                if [ ! -d $HOME/.ssh/config.d/ ]; then
                    poet bootstrap
                fi
            fi
        fi
    done
}

gh::_generate_ssh_file() {
	local target_directory="$1"
	local private_key_name="$2"
	local email="$3"

	mkdir -p ${target_directory}
	ssh-keygen -t rsa -C "${email}" -f "${target_directory}/${private_key_name}" -N ''

	cat << EOF > $HOME/.ssh/config.d/github.com-local-motion
Host github.com-local-motion
   HostName github.com
   User git
   IdentitiesOnly          yes
   IdentityFile ${target_directory}/${private_key_name}
EOF
    debug "Generated SSH config at $HOME/.ssh/config.d/github.com-local-motion"
}

gh::_copy_to_clipboard() {
    local file_to_copy=$1
    cat ${file_to_copy} | pbcopy
}

gh::_append_to_zshrc() {
    local rc_file=$HOME/.zshrc
    local source_script=${script_dir}/gh_local_motion.sh
    if [[ -f ${rc_file} ]]; then
        if grep -q "source ${source_script}" ${rc_file}; then
            info "${rc_file} already sources ${source_script}"
        else
            echo "source ${source_script}" >> ${rc_file}
            info "Updated ${rc_file} with 'source ${source_script}'"
        fi
    fi
}

# From https://medium.freecodecamp.org/manage-multiple-github-accounts-the-ssh-way-2dadc30ccaca
gh::setup_local_motion_ssh_key() {
	local target_directory="$HOME/.ssh/local-motion"
	local private_key_name="id_rsa_local_motion"
	local public_key_name="${private_key_name}.pub"

    info "This script will:"
    echo "  1) install rbenv"
    echo "  1) install ruby 2.5.1"
    echo "  2) install a ruby program called Poet, which will split your "
    echo "     longish ~/.ssh/config into files in ~/.ssh/config.d/ and let poet join them for you."
    echo "  "
    echo "     See https://github.com/awendt/poet for more information."
    echo "  3) Generate a new key-pair at ${target_directory}/${private_key_name}[.pub]"
    echo "  4) Add a new Local Motion specific SSH config file at $HOME/.ssh/config.d/github.com-local-motion"
    echo "  5) Append this script to .bashrc and/or .zshrc"
    echo "  "
    ask "Please confirm that the above is OK with you " Y || exit 1

	ruby::install poet
    gh::_generate_ssh_file ${target_directory} ${private_key_name} ${private_email}
    gh::_append_to_zshrc
    gh::_copy_to_clipboard ${target_directory}/${public_key_name}

    echo ""
    info "The public key has been pasted to your clipboard."
    info "Go to https://github.com/settings/ssh/new and paste it in there"
    echo ""
}
gh::setup_git_for_work_on_localmotion() {
	GIT_AUTHOR_NAME=${author}
	GIT_COMMITTER_NAME="${author}"
	git config --global user.name "${author}"
	GIT_AUTHOR_EMAIL="${private_email}"
	GIT_COMMITTER_EMAIL="${private_email}"
	git config --global user.email "${private_email}"
	GH_SSH_KEY_SUFFIX="-local-motion"

	git config --global alias.cl
}
# Proxy any call to git executable. In case of clone, apply '-local-motion' infix.
function git {
  if [[ "$1" == "clone" && "$@" != *"--help"* ]]; then
    shift 1
    local modified_clone_url=$(echo "$@" | sed "s/git@github.com/&${GH_SSH_KEY_SUFFIX}/")
    if [[ ${modified_clone_url} != $@ ]]; then
        warn "${script_name}: Modified clone URL to ${modified_clone_url}"
    fi
    command git clone "${modified_clone_url}"
  elif [[ "$1" == "remote" && "$@" != *"--help"* ]]; then
    shift 1
    local modified_remote_url=$(echo "$@" | sed "s/git@github.com/&${GH_SSH_KEY_SUFFIX}/")
    if [[ ${modified_remote_url} != $@ ]]; then
        warn "${script_name}: Modified remote URL to ${modified_remote_url}"
    fi
    command git remote "$@"
  else
    command git "$@"
  fi
}

# default to Local Motion project
if [[ "$1" == "setup" ]]; then
    gh::setup_local_motion_ssh_key
else
    gh::setup_git_for_work_on_localmotion
fi
