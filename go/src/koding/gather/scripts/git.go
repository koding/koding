package scripts

import "koding/gather/metrics"

var (
	GitRemotes = &metrics.Metric{
		Name:      "git_repos",
		Collector: metrics.NewScriptCmd("scripts/bash/git_remotes.sh"),
		Output:    twoColumnMultiple(),
	}
)
