package scripts

import (
	"fmt"
	"koding/gather/metrics"
)

var (
	TotalDisk = &metrics.Metric{
		Name:      "total_disk",
		Collector: df(2),
		Output:    singleNumber(),
	}

	UsedDisk = &metrics.Metric{
		Name:      "used_disk",
		Collector: df(3),
		Output:    singleNumber(),
	}

	FreeDisk = &metrics.Metric{
		Name:      "free_disk",
		Collector: df(4),
		Output:    singleNumber(),
	}

	PerUsedDisk = &metrics.Metric{
		Name:      "per_used_disk",
		Collector: df(5),
		Output:    singleNumber(),
	}
)

func df(location int) *metrics.MultipleCmd {
	return metrics.NewMultipleCmd(
		metrics.NewSingleCmd("df", "-l"),
		metrics.NewSingleCmd("grep", "/dev"),
		metrics.NewSingleCmd("awk", fmt.Sprintf(`{print $%d}`, location)),
	)
}
