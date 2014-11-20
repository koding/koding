package metrics

import "github.com/codeskyblue/go-sh"

type ScriptCmd struct {
	Filename string
	Args     []interface{}
}

func NewScriptCmd(filename string, args ...interface{}) *ScriptCmd {
	return &ScriptCmd{Filename: filename, Args: args}
}

func (s *ScriptCmd) Run() ([]byte, error) {
	allArgs := append([]interface{}{s.Filename}, s.Args...)
	return sh.Command("bash", allArgs...).Output()
}
