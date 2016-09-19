package logrotate

import "io"

// CountingWriter is a writer that wraps writes to W,
// counting bytes written.
type CountingWriter struct {
	W io.Writer // underlying writer
	N *int64    // count of bytes written
}

var _ io.Writer = (*CountingWriter)(nil)

func (cw *CountingWriter) Write(p []byte) (int, error) {
	n, err := cw.W.Write(p)
	*cw.N += int64(n)
	return n, err
}

// CountingReader is a reader that wraps reads to RS,
// counting bytes read.
type CountingReader struct {
	RS io.ReadSeeker // underlying reader
	N  *int64        // count of bytes read
}

var _ io.ReadSeeker = (*CountingReader)(nil)

// Read implements the io.Reader interface.
func (cr *CountingReader) Read(p []byte) (int, error) {
	n, err := cr.RS.Read(p)
	*cr.N += int64(n)
	return n, err
}

// Seek implements the io.Seeker interface.
func (cr *CountingReader) Seek(offset int64, whence int) (int64, error) {
	return cr.RS.Seek(offset, whence)
}

func min(i, j int64) int64 {
	if i < j {
		return i
	}

	return j
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}
