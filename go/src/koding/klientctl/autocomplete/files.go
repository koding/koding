package autocomplete

const (
	fishFilename = "kd.fish"
	// The fishDir location requires the home directory.
	fishInstallDir = "%s/.config/fish/completions"
	bashFilename   = "kd"
	bashInstallDir = "/etc/bash_completion.d"

	// The fish completion file, usually placed in ~/.config/fish/completions/kd.fish
	fishCompletionContents = `#!/usr/bin/env fish

function __kd_subcommand
  set cmd (commandline -opc)
  if test (count $cmd) -lt 2
    return 0
  end
  echo "$cmd[2]"
  return 0
end

function __kd_subcommand_args
  set cmd (commandline -op)
  set cmdCount (count $cmd)
  if test $cmdCount -lt 3
    return 0
  end
  # Ensure fish takes the args as separate, not a single string as is the case
  # if we used $cmd[3..cmdCount]
  for i in (seq 3 $cmdCount)
    echo $cmd[$i]
  end
  return 0
end

complete -f -c kd -a '(kd (__kd_subcommand) --generate-bash-completion (__kd_subcommand_args))'
`

	// The bash completion file, usually placed in /etc/bash_completion.d/kd
	bashCompletionContents = `#!/bin/bash

PROG="kd"

_cli_bash_autocomplete() {
  local cur opts base
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  # Experimental full completion - not working yet
  #opts=$( ${COMP_WORDS[@]:0:2} --generate-bash-completion ${COMP_WORDS[@]:2:$COMP_CWORD} )
  opts=$( ${COMP_WORDS[@]:0:$COMP_CWORD} --generate-bash-completion )
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}

complete -F _cli_bash_autocomplete $PROG
`

	// The script appended to the users bashrc, to source the users autocomplete
	// scripts.
	bashSource = `
source /etc/bash_completion.d/kd
`
)
