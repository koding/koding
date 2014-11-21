package scripts

import (
	"fmt"
	"koding/gather/metrics"
	"strconv"
	"strings"
)

var (
	TotalDisk = &metrics.Metric{
		Name:      "total_disk",
		Collector: df(2),
		Output:    dfo(),
	}

	UsedDisk = &metrics.Metric{
		Name:      "used_disk",
		Collector: df(3),
		Output:    dfo(),
	}

	FreeDisk = &metrics.Metric{
		Name:      "free_disk",
		Collector: df(4),
		Output:    dfo(),
	}

	PerUsedDisk = &metrics.Metric{
		Name:      "per_used_disk",
		Collector: df(5),
		Output:    dfo(),
	}
)

func df(location int) *metrics.MultipleCmd {
	return metrics.NewMultipleCmd(
		metrics.NewSingleCmd("df", "-l"),
		metrics.NewSingleCmd("grep", "/dev"),
		metrics.NewSingleCmd("awk", fmt.Sprintf(`{print $%d}`, location)),
	)
}

func dfo() func([]byte) (map[string]interface{}, error) {
	return func(raw []byte) (map[string]interface{}, error) {
		input := strings.TrimSpace(fmt.Sprintf("%s", raw))
		input = strings.Trim(input, "%")

		num, err := strconv.Atoi(input)
		if err != nil {
			fmt.Println(">>>>>>>>>>", err)
		}

		values := map[string]interface{}{"data": num}

		return values, nil
	}
}
