package kodingcontext

import (
	"io"

	"github.com/mitchellh/cli"
)

const (
	ErrorPrefix  = "e:"
	OutputPrefix = "o:"
)

// NewUI returns a cli.UI
func NewUI(w io.Writer) *cli.PrefixedUi {
	return &cli.PrefixedUi{
		AskPrefix:    OutputPrefix,
		OutputPrefix: OutputPrefix,
		InfoPrefix:   OutputPrefix,
		ErrorPrefix:  ErrorPrefix,

		Ui: &cli.BasicUi{Writer: w},
	}
}
