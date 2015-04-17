package commands

import (
	"bytes"

	"github.com/mitchellh/cli"
)

const (
	ErrorPrefix  = "e:"
	OutputPrefix = "o:"
)

func NewUI(b *bytes.Buffer) *cli.PrefixedUi {
	return &cli.PrefixedUi{
		AskPrefix:    OutputPrefix,
		OutputPrefix: OutputPrefix,
		InfoPrefix:   OutputPrefix,
		ErrorPrefix:  ErrorPrefix,

		// we can override this later easily
		Ui: &cli.BasicUi{Writer: b},
	}
}
