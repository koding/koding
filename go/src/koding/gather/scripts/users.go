package scripts

import (
	"fmt"
	"koding/gather/metrics"
	"strings"
)

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

// Parses two column, multi row entries.
// Example Args:
//   Args:
//			root /bin/sh
//			root /bin/sh
//			daemon /usr/bin/false
//	 Return
//		map[string]inteface{"root":"/bin/sh", "daemon":"/usr/bin/false"}
func twoColumnMultiple() func([]byte) (map[string]interface{}, error) {
	return func(raw []byte) (map[string]interface{}, error) {
		input := strings.TrimSpace(fmt.Sprintf("%s", raw))
		lines := strings.Split(input, "\n")

		output := map[string]interface{}{}

		for _, line := range lines {
			split := strings.Split(line, " ")
			if len(split) != 2 {
				continue
			}

			output[split[0]] = split[1]
		}

		return output, nil
	}
}
