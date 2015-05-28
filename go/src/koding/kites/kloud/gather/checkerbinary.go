package gather

import (
	"bytes"
	"encoding/json"
	"os/exec"

	"github.com/kr/pretty"
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

	pretty.Println(results)

	return results, nil
}
