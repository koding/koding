package scripts

import "koding/gather/metrics"

var (
	NumBashConfigLines = &metrics.Metric{
		Name:      "number_of_bash_config_lines",
		Collector: metrics.NewScriptCmd("scripts/bash/bash_config_lines.sh"),
		Output:    singleNumber(),
	}

	NumZshConfigLines = &metrics.Metric{
		Name:      "number_of_zsh_config_lines",
		Collector: metrics.NewScriptCmd("scripts/bash/zsh_config_lines.sh"),
		Output:    singleNumber(),
	}

	NumFishConfigLines = &metrics.Metric{
		Name:      "number_of_fish_config_lines",
		Collector: metrics.NewScriptCmd("scripts/bash/fish_config_lines.sh"),
		Output:    singleNumber(),
	}
)
