package scripts

import (
	"fmt"
	"strings"
)

// Parses two column, multi row entries.
//
// Example Args:
//   Args:
//			root /bin/sh
//			daemon /usr/bin/false
//	 Returns:
//			{"values" : [
//         {"field":"root",   "value":"/bin/sh"}
//         {"field":"daemon", "value":"/usr/bin/false"}
//      ]
func twoColumnMultiple() func([]byte) (map[string]interface{}, error) {
	return func(raw []byte) (map[string]interface{}, error) {
		input := strings.TrimSpace(fmt.Sprintf("%s", raw))
		lines := strings.Split(input, "\n")

		values := []map[string]interface{}{}

		for _, line := range lines {
			split := strings.Split(line, " ")
			if len(split) != 2 {
				continue
			}

			item := map[string]interface{}{"field": split[0], "value": split[1]}
			values = append(values, item)
		}

		outer := map[string]interface{}{"values": values}

		return outer, nil
	}
}
