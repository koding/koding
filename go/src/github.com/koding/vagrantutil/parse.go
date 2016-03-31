package vagrantutil

import (
	"bufio"
	"strings"
)

// parseData parses the given vagrant type field from the machine readable
// output (records).
func (v *Vagrant) parseData(records [][]string, typeName string) (string, error) {
	data := ""
	for _, record := range records {
		// first three are defined, after that data is variadic, it contains
		// zero or more information. We should have a data, otherwise it's
		// useless.
		if len(record) < 4 {
			continue
		}

		if typeName == record[2] {
			data = record[3]
			if data != "" {
				break
			}
		}
	}

	if data == "" {
		return "", v.errorf("couldn't parse data for vagrant type: %q", typeName)
	}

	return data, nil
}

func (v *Vagrant) parseRecords(out string) (recs [][]string, err error) {
	scanner := bufio.NewScanner(strings.NewReader(out))

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		row := strings.Split(scanner.Text(), ",")
		recs = append(recs, row)
	}

	if err := scanner.Err(); err != nil {
		return nil, v.error(err)
	}

	return recs, nil
}
