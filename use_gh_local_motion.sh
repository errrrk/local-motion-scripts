#!/usr/bin/env bash

# This is my personal private email. You probably want to have your own configuration here.
private_email="43416374+errrrk@users.noreply.github.com"
author="Errrrk"

script_name=$(basename -- $0)

gh::configure_git_for_work_on_localmotion() {
	GIT_AUTHOR_NAME=${author}
	GIT_COMMITTER_NAME="${author}"
	git config --global user.name "${author}"
	GIT_AUTHOR_EMAIL="${private_email}"
	GIT_COMMITTER_EMAIL="${private_email}"
	git config --global user.email "${private_email}"

    # Set same suffix as used in ./setup_gh_local_motion.sh
	GH_SSH_KEY_SUFFIX="-local-motion"
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
gh::configure_git_for_work_on_localmotion
