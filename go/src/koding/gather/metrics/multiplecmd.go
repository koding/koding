package metrics

import "github.com/codeskyblue/go-sh"

type MultipleCmd struct {
	Cmds []*SingleCmd
}

func NewMultipleCmd(cmds ...*SingleCmd) *MultipleCmd {
	multipleCmds := &MultipleCmd{}

	for _, cmd := range cmds {
		multipleCmds.Cmds = append(multipleCmds.Cmds, cmd)
	}

	return multipleCmds
}

func (m *MultipleCmd) Run() ([]byte, error) {
	firstCmd := m.Cmds[0]
	cmdBucket := sh.Command(firstCmd.Cmd, firstCmd.Args...)

	for _, cmd := range m.Cmds[1:] {
		cmdBucket.Command(cmd.Cmd, cmd.Args...)
	}

	return cmdBucket.Output()
}
