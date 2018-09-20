# local-motion-scripts

We're working on a project called (Local Motion)[https://github.com/local-motion]. This repository
contains scripts that are useful when setting up my local environment for that project.

### gh_local_motion.sh
You can run the initial setup. It'll show you the changes that will be made, and ask for 
confirmation.
```commandline
setup_gh_local_motion.sh
```

The script alters your `$HOME/.zshrc` to work with (Local Motion)[https://github.com/local-motion] by
sourcing `use_gh_local_motion.sh` each time the terminal is opened.