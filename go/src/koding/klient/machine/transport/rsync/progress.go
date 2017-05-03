package rsync

import (
	"fmt"
	"io"
	"strings"

	humanize "github.com/dustin/go-humanize"
	"github.com/mitchellh/ioprogress"
)

// Progress is a default function used for writing command status to `w` writer.
func Progress(w io.Writer, nAll, sizeAll int64) func(n, size, speed int64, err error) {
	const noop = 0

	maxLength, speedLast := 0, int64(0)
	return func(n, size, speed int64, err error) {
		if err == io.EOF {
			n, size, speed = nAll, sizeAll, speedLast
		}

		drawFunc := ioprogress.DrawTerminalf(w, func(_, _ int64) string {
			line := fmt.Sprintf("Copying files: %.1f%% (%d/%d), %s/%s | %s/s",
				percentage(size, sizeAll), // percentage status.
				n,    // number of downloaded files.
				nAll, // number of all files being downloaded.
				humanize.IBytes(uint64(size)),    // size of downloaded files.
				humanize.IBytes(uint64(sizeAll)), // total size.
				humanize.IBytes(uint64(speed)),   // current downloading speed.
			)

			if len(line) < maxLength {
				line = fmt.Sprintf("%s%s", line, strings.Repeat(" ", maxLength-len(line)))
			}
			maxLength, speedLast = len(line), speed

			return line
		})

		drawFunc(noop, noop) // We are not using default values.
		if err != nil {
			drawFunc(-1, -1) // Finish drawing.
		}
	}
}

func percentage(size, sizeAll int64) float64 {
	if sizeAll == 0 {
		return 0.0
	}

	return float64(size) / float64(sizeAll) * 100.0
}
