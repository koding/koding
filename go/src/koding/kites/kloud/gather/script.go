package gather

import (
	"bytes"
	"encoding/json"
	"os/exec"
)

type Script struct {
	Path string
}

func (s *Script) Run() (*Result, error) {
	output, err := exec.Command(s.Path).Output()
	if err != nil {
		return nil, err
	}

	bites := bytes.NewBuffer(output)

	var result = &Result{}
	if err := json.NewDecoder(bites).Decode(result); err != nil {
		return nil, err
	}

	return result, nil
}

type Result struct {
	Error     error
	Category  string
	Name      string
	Type      string
	Exists    bool
	Timestamp string
}
