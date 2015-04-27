package kodingcontext

import (
	"io"

	"github.com/mitchellh/cli"
)

const (
	// ErrorPrefix all errors will start with this
	ErrorPrefix = "e:"

	// OutputPrefix all outputs will start with this, except errors
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
