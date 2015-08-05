package gatherrun

import (
	"bytes"
	"encoding/json"
	"os/exec"
)

type Options map[string]interface{}

type GatherBinary struct {
	Path string
}

func (g *GatherBinary) Run() ([]interface{}, error) {
	output, err := exec.Command(g.Path).Output()
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
