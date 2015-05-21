package gather

import (
	"bytes"
	"encoding/json"
	"os/exec"
)

type Options map[string]interface{}

type CheckerBinary struct {
	Path string
}

func (s *CheckerBinary) Run() ([]interface{}, error) {
	output, err := exec.Command(s.Path, "xAboBy").Output()
	if err != nil {
		return nil, err
	}

	bites := bytes.NewBuffer(output)

	var results []interface{}
	if err := json.NewDecoder(bites).Decode(&results); err != nil {
		return nil, err
	}

	return results, nil
}
