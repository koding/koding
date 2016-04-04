package vagrantutil

import (
	"bufio"
	"fmt"
	"strings"
)

// parseData parses the given vagrant type field from the machine readable
// output (records).
func parseData(records [][]string, typeName string) (string, error) {
	data := ""
	for _, record := range records {
		// first three are defined, after that data is variadic, it contains
		// zero or more information. We should have a data, otherwise it's
		// useless.
		if len(record) < 4 {
			continue
		}

		if typeName == record[2] && record[3] != "" {
			data = record[3]
			break
		}
	}

	if data == "" {
		return "", fmt.Errorf("couldn't parse data for vagrant type: %q", typeName)
	}

	return data, nil
}

func parseRecords(out string) (recs [][]string, err error) {
	scanner := bufio.NewScanner(strings.NewReader(out))

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		row := strings.Split(line, ",")
		recs = append(recs, row)
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return recs, nil
}
