package stream

import (
	"io"
	"os"
	"sync"

	"github.com/koding/logging"
)

// Streamer defines data streams used by endpoints for their I/O.
type Streamer interface {
	In() io.Reader
	Out() io.Writer
	Err() io.Writer
	Log() logging.Logger
}

type compatStreamer struct {
	once sync.Once
	log  logging.Logger
}

func (s *compatStreamer) In() io.Reader  { return os.Stdin }
func (s *compatStreamer) Out() io.Writer { return os.Stdout }
func (s *compatStreamer) Err() io.Writer { return os.Stderr }

func (s *compatStreamer) Log() logging.Logger {
	if s.log != nil {
		return s.log
	}

	return logging.NewLogger("kd")
}

func (s *compatStreamer) SetLog(log logging.Logger) {
	s.once.Do(func() {
		s.log = log
	})
}

// DefaultStreams implement Streamer interface. This is a fallback variable
// that stores default streams.
var DefaultStreams = &compatStreamer{}
