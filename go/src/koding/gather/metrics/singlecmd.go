package metrics

import "github.com/codeskyblue/go-sh"

type SingleCmd struct {
	Cmd  string
	Args []interface{}
}

func NewSingleCmd(cmd string, args ...interface{}) *SingleCmd {
	return &SingleCmd{Cmd: cmd, Args: args}
}

func (s *SingleCmd) Run() ([]byte, error) {
	return sh.Command(s.Cmd, s.Args...).Output()
}
