package scripts

import (
	"fmt"
	"koding/gather/metrics"
)

var (
	TotalDisk   = &metrics.Metric{Name: "total_disk", Collector: df(2)}
	UsedDisk    = &metrics.Metric{Name: "used_disk", Collector: df(3)}
	FreeDisk    = &metrics.Metric{Name: "free_disk", Collector: df(4)}
	PerUsedDisk = &metrics.Metric{Name: "per_used_disk", Collector: df(5)}
)

func df(location int) *metrics.MultipleCmd {
	return metrics.NewMultipleCmd(
		metrics.NewSingleCmd("df", "-lh"),
		metrics.NewSingleCmd("grep", "/dev"),
		metrics.NewSingleCmd("awk", fmt.Sprintf(`{print $%d}`, location)),
	)
}
