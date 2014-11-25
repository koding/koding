package scripts

import "koding/gather/metrics"

var (
	NumGitRepos = &metrics.Metric{
		Name:      "number_of_git_repos",
		Collector: metrics.NewScriptCmd("scripts/bash/number_of_git_repos.sh"),
		Output:    singleNumber(),
	}

	GitRemotes = &metrics.Metric{
		Name:      "git_remotes",
		Collector: metrics.NewScriptCmd("scripts/bash/git_remotes.sh"),
		Output:    twoColumnMultiple(),
	}
)
