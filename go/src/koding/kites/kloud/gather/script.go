package gather

import (
	"bytes"
	"encoding/json"
	"os/exec"
)

type Result struct {
	Error     error   `json:"error",omitempty"`
	Name      string  `json:"name"`
	Type      string  `json:"type"`
	Boolean   bool    `json:"boolean",omitempty`
	Number    float64 `json:"number",omitempty`
	Timestamp string  `json:"@timestamp"`
}

type Options map[string]interface{}

type CheckerBinary struct {
	Path string
}

func (s *CheckerBinary) Run() (*Result, error) {
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
