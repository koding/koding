package kodingcontext

import (
	"fmt"
	"io"
	"os"

	"github.com/mitchellh/cli"
)

const (
	// ErrorPrefix all errors will start with this
	ErrorPrefix = "e:"

	// OutputPrefix all outputs will start with this, except errors
	OutputPrefix = "o:"
)

// NewUI returns a cli.UI
func NewUI(w io.Writer, traceID string) *cli.PrefixedUi {
	if traceID == "" {
		return &cli.PrefixedUi{
			AskPrefix:    OutputPrefix,
			OutputPrefix: OutputPrefix,
			InfoPrefix:   OutputPrefix,
			ErrorPrefix:  ErrorPrefix,
			Ui: &cli.BasicUi{
				Writer: w,
			},
		}
	}

	prefix := fmt.Sprintf("[%s] %s", traceID, OutputPrefix)

	return &cli.PrefixedUi{
		AskPrefix:    prefix,
		OutputPrefix: prefix,
		InfoPrefix:   prefix,
		ErrorPrefix:  ErrorPrefix,
		Ui: &cli.BasicUi{
			Writer:      os.Stderr,
			ErrorWriter: io.MultiWriter(os.Stderr, w),
		},
	}
}
