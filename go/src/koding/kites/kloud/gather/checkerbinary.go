package gather

import (
	"bytes"
	"encoding/json"
	"os/exec"
)

type Result map[string]interface{}
type Options map[string]interface{}

type CheckerBinary struct {
	Path string
}

func (s *CheckerBinary) Run() (Result, error) {
	output, err := exec.Command(s.Path, "xAboBy").Output()
	if err != nil {
		return nil, err
	}

	bites := bytes.NewBuffer(output)

	var result = Result{}
	if err := json.NewDecoder(bites).Decode(result); err != nil {
		return nil, err
	}

	return result, nil
}
