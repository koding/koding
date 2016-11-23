package scripts

import "koding/gather/metrics"

var (
	NumUsers = &metrics.Metric{
		Name:      "number_of_users",
		Collector: metrics.NewScriptCmd("scripts/bash/number_of_users.sh"),
		Output:    singleNumber(),
	}

	UsersShell = &metrics.Metric{
		Name:      "users_shell",
		Collector: metrics.NewScriptCmd("scripts/bash/users_shell.sh"),
		Output:    twoColumnMultiple(),
	}
)
