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

# This command returns mount IDs and base local mount paths.
# Usage: __kd_remote_machines [OPTIONS]
# Available OPTIONS:
#     -e Exclude mount paths.
#
__kd_existing_mounts()
{
    local kd_output flag cmd_options OPTIND=1
    while getopts "e" flag "$@"; do
        case $flag in
            e) cmd_options="${cmd_options} --base-path=false" ;;
        esac
    done

    if kd_output=$(kd machine mount identifiers ${cmd_options} 2>/dev/null); then
        out=($(echo "${kd_output}"))
        COMPREPLY=( "${COMPREPLY[@]}"  $( compgen -W "${out[*]}" -- "$cur" ) )
    fi
}

# This command provides auto completion abilities for mount subcommand.
__kd_mount_completion()
{
    case ${prev} in
        mount)
            if [[ "$cur" == *:* ]]; then
                _filedir -d # Add remote file support.
            else
                __kd_remote_machines -s ":"
            fi
            ;;
        *)
            _filedir -d
            ;;
    esac
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
        kd_machine_umount | kd_machine_unmount | kd_unmount | kd_umount | kd_machine_mount_inspect | kd_sync | kd_sync_pause | kd_sync_resume | kd_machine_mount_sync_pause | kd_machine_mount_sync_resume)
            __kd_existing_mounts -e
            ;;
        kd_mount | kd_machine_mount)
            __kd_mount_completion
            ;;
        *)
            ;;
    esac
}
`
)
