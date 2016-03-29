package metrics

const (
	EventInstall      EventName = "installed kd"
	EventMount        EventName = "mounted machine"
	EventUnmount      EventName = "unmounted machine"
	EventRun          EventName = "ran command on mount"
	EventRepair       EventName = "attempted to repair machine"
	EventRepairFailed EventName = "failed to repair machine"
	EventSSH          EventName = "attempted to ssh to machine"
	EventSSHManaged   EventName = "attempted to ssh into managed machine"
	EventSSHFailed    EventName = "ssh to machine failed"
)
