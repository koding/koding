package scripts

import "koding/gather/metrics"

var (
	FileTypes = &metrics.Metric{
		Name:      "file_types",
		Collector: metrics.NewScriptCmd("scripts/bash/file_types.sh"),
	}
)
