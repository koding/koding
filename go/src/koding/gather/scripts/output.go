package scripts

import (
	"fmt"
	"strconv"
	"strings"
)

// Parses single number entry into float64.
//
// Example:
//   Args: 		1.3
//	 Returns: {"value" : 1.3}
func singleNumber() func([]byte) (map[string]interface{}, error) {
	return func(raw []byte) (map[string]interface{}, error) {
		input := strings.TrimSpace(fmt.Sprintf("%s", raw))
		input = strings.Trim(input, "%")

		num, err := strconv.ParseFloat(input, 64)
		if err != nil {
			return nil, err
		}

		values := map[string]interface{}{"value": num}

		return values, nil
	}
}

// Parses two column, multi row entries.
//
// Example:
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

// Parses single number entry into boolean.
//	0 is true, 1 is false.
//
// Example:
//   Args: 		0
//	 Returns: {"value" : true}
func singleNumberIntoBool() func([]byte) (map[string]interface{}, error) {
	return func(raw []byte) (map[string]interface{}, error) {
		singleResult, err := singleNumber()(raw)
		if err != nil {
			return nil, err
		}

		rawValue, ok := singleResult["value"]
		if !ok {
			fmt.Printf(">>>> No value in result: %v\n", raw)
			return nil, nil
		}

		result := rawValue.(float64)

		var value bool

		switch result {
		case 0:
			value = true
		case 1:
			value = false
		default:
			fmt.Printf(">>>> Unable to parse %v into bool\n", result)
		}

		values := map[string]interface{}{"value": value}

		return values, nil
	}
}
