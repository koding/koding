package gatherrun

import (
	"bytes"
	"encoding/json"
	"errors"
	"os"
	"os/exec"

	"github.com/koding/klient/command"
)

type Options map[string]interface{}

type GatherBinary struct {
	Path       string
	ScriptType string
}

func (g *GatherBinary) Run() ([]interface{}, error) {
	cmd := exec.Command(g.Path)
	cmd.Env = append(os.Environ(), envVarName+"="+g.ScriptType)

	output, err := command.NewOutput(cmd)
	if err != nil {
		return nil, err
	}

	if output.Stderr != "" {
		return nil, errors.New(output.Stderr)
	}

	buf := bytes.NewBuffer([]byte(output.Stdout))

	var results []interface{}
	if err := json.NewDecoder(buf).Decode(&results); err != nil {
		return nil, err
	}

	return results, nil
}
