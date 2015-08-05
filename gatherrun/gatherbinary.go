package gatherrun

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
)

type Options map[string]interface{}

type GatherBinary struct {
	Path       string
	ScriptType string
}

func (g *GatherBinary) Run() ([]interface{}, error) {
	cmd := exec.Command(g.Path)
	cmd.Env = append(os.Environ(), g.ScriptType)

	output, err := cmd.Output()
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
