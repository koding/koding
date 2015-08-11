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
	cmd.Env = append(os.Environ(), envVarName+"="+g.ScriptType)

	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	buf := bytes.NewBuffer(output)

	var results []interface{}
	if err := json.NewDecoder(buf).Decode(&results); err != nil {
		return nil, err
	}

	return results, nil
}
