#!/usr/bin/env bash

script_name=$(basename -- $0)
private_email="43416374+errrrk@users.noreply.github.com"
author="Errrrk"

ruby::install() {
    if test ! $(which rbenv); then
        echo "Installing rbenv..."
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

# From https://medium.freecodecamp.org/manage-multiple-github-accounts-the-ssh-way-2dadc30ccaca
gh::generate_local_motion_ssh_key() {
	ruby::install poet
	mkdir -p ~/.ssh/local-motion
	ssh-keygen -t rsa -C "${private_email}" -f "$HOME/.ssh/local-motion/id_rsa_local_motion"

	cat << EOF > $HOME/.ssh/config.d/github.com-local-motion
Host github.com-local-motion
   HostName github.com
   User git
   IdentitiesOnly          yes
   IdentityFile ~/.ssh/local-motion/id_rsa_local_motion
EOF
    cat $HOME/.ssh/local-motion/id_rsa_local_motion.pub | pbcopy
    echo "The public key has been pasted to your clipboard."
    echo "Go to https://github.com/settings/ssh/new and paste it in there"
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
        echo "${script_name}: Modified clone URL to ${modified_clone_url}"
    fi
    command git clone "${modified_clone_url}"
  elif [[ "$1" == "remote" && "$@" != *"--help"* ]]; then
    shift 1
    local modified_remote_url=$(echo "$@" | sed "s/git@github.com/&${GH_SSH_KEY_SUFFIX}/")
    if [[ ${modified_remote_url} != $@ ]]; then
        echo "${script_name}: Modified remote URL to ${modified_remote_url}"
    fi
    command git remote "$@"
  else
    command git "$@"
  fi
}

# default to Local Motion project
if [[ "$1" == "generate" ]]; then
    gh::generate_local_motion_ssh_key
fi

gh::setup_git_for_work_on_localmotion