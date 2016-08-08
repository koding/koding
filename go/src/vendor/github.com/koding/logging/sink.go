package logging

import (
	"fmt"
	"os"
	"sync"
)

/////////////////
//             //
// SinkHandler //
//             //
/////////////////

// SinkHandler sends log records to buffered channel, the logs are written in a dedicated routine consuming the channel.
type SinkHandler struct {
	inner   Handler
	sinkCh  chan *Record
	bufSize int
	wg      sync.WaitGroup
}

// NewSinkHandler creates SinkHandler with sink channel buffer size bufSize that wraps inner handler for writing logs.
// When SinkHandler is created a go routine is started. When not used always call Close to terminate go routine.
func NewSinkHandler(inner Handler, bufSize int) *SinkHandler {
	b := &SinkHandler{
		inner:   inner,
		sinkCh:  make(chan *Record, bufSize),
		bufSize: bufSize,
	}

	b.wg.Add(1)
	go b.process()

	return b
}

// process reads log records from sinkCh and calls inner log handler to write it.
func (b *SinkHandler) process() {
	for {
		rec, ok := <-b.sinkCh
		if !ok {
			b.inner.Close()
			break
		}

		b.inner.Handle(rec)
	}
	b.wg.Done()
}

// Status reports sink capacity and length.
func (b *SinkHandler) Status() (int, int) {
	return b.bufSize, len(b.sinkCh)
}

// SetLevel sets logging level for handler
func (b *SinkHandler) SetLevel(l Level) {
	b.inner.SetLevel(l)
}

// SetFormatter sets logging formatter for handler
func (b *SinkHandler) SetFormatter(f Formatter) {
	b.inner.SetFormatter(f)
}

// Handle puts rec to the sink.
func (b *SinkHandler) Handle(rec *Record) {
	select {
	case b.sinkCh <- rec:
	default:
		fmt.Fprintf(os.Stderr, "SinkHandler buffer too small dropping record\n")
	}
}

// Close closes the sink channel, inner handler will be closed when all pending logs are processed.
// Close blocks until all the logs are processed.
func (b *SinkHandler) Close() {
	close(b.sinkCh)
	b.wg.Wait()
}
