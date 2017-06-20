package commands

const (
	bashCompletionFunc = `
# This function adds available remote machines to COMREPLY.
# Usage: __kd_remote_machines [OPTIONS]
# Available OPTIONS:
#     -p PREFIX Prefix to add to each machine name
#     -s SUFFIX Suffix to add to each machine name
#
__kd_remote_machines()
{
    local kd_output flag OPTIND=1
    local words=()

    if kd_output=$(kd machine identifiers 2>/dev/null); then
        out=($(echo "${kd_output}"))
        while getopts "p:s:" flag "$@"; do
            case $flag in
                p) words=${out[@]/#/$OPTARG}; out=(${words[@]}) ;;
                s) words=${out[@]/%/$OPTARG}; out=(${words[@]}) ;;
            esac
        done

        COMPREPLY=( "${COMPREPLY[@]}" $( compgen -W "${words[*]}" -- "$cur" ) )
    fi
}

# This command provides auto completion abilities for exec subcommand.
__kd_exec_completion()
{
    if [[ ${prev} == "exec" ]]; then
        __kd_remote_machines -p "@"
        _filedir
    fi
}

# This command provides auto completion abilities for cp subcommand.
__kd_cp_completion()
{
    case ${prev} in
        *:*)
            _filedir
            ;;
        *)
            if [[ "$cur" == *: ]]; then
                _filedir # Add remote file support.
            else
                __kd_remote_machines -s ":"
                _filedir
            fi
            ;;
    esac
}

__kd_parse_mount()
{
	local kd_output
    if kd_output=$(kd machine mount identifiers 2>/dev/null); then
        out=($(echo "${kd_output}"))
        COMPREPLY=( $( compgen -W "${out[*]}" -- "$cur" ) )
    fi
}

__custom_func() {
    case ${last_command} in
        kd_machine_ssh | kd_ssh | kd_machine_config_show | kd_machine_start | kd_machine_stop)
            __kd_remote_machines
            ;;
        kd_machine_exec | kd_exec)
            __kd_exec_completion
            ;;
        kd_machine_cp | kd_cp)
            __kd_cp_completion
            ;;
        kd_machine_umount | kd_machine_unmount | kd_unmount | kd_umount | kd_machine_mount_inspect)
            __kd_parse_mount
            ;;
        *)
            ;;
    esac
}
`
)
