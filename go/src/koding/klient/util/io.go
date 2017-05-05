package util

import (
    "io"
    "os/exec"
    "unicode/utf8"

    "github.com/koding/kite/dnode"
)

type Pipes struct {
    In      io.WriteCloser
    Out     io.ReadCloser
    Err     io.ReadCloser
}

// GetPipes takes an *exec.Cmd and returns all of the pipes
// associated with said Cmd.
func GetPipes(c *exec.Cmd) (*Pipes, error) {
    p := &Pipes{}

    var err error

    if p.In, err = c.StdinPipe(); err != nil {
        return nil, err
    }

    if p.Out, err = c.StdoutPipe(); err != nil {
        return nil, err
    }

    if p.Err, err = c.StderrPipe(); err != nil {
        return nil, err
    }

    return p, nil
}

// PassTo takes an io.Reader and reads data from said reader, passing
// all chunks to the provided dnode.Function that is assumed to be
// waiting for data from the reader.
func PassTo(to dnode.Function, from io.Reader) {
    buf := make([]byte, (1<<12)-utf8.UTFMax, 1<<12)

    for {
        n, err := from.Read(buf)

        // Most likely and EOF here, so we are done.
        if err != nil {
            break
        }

        for n < cap(buf)-1 {
            r, _ := utf8.DecodeLastRune(buf[:n])

            if r != utf8.RuneError {
                break
            }

            from.Read(buf[n : n+1])
            n++
        }

        if err := to.Call(string(filterInvalidUTF8(buf[:n]))); err != nil {
            // TODO (acbodine): Make PassTo() take an error channel as an
            // argument to force callers to handler their own errors.

            break
        }
    }
}

func filterInvalidUTF8(buf []byte) []byte {
	i := 0
	j := 0
	for {
		r, l := utf8.DecodeRune(buf[i:])
		if l == 0 {
			break
		}
		if r < 0xD800 {
			if i != j {
				copy(buf[j:], buf[i:i+l])
			}
			j += l
		}
		i += l
	}
	return buf[:j]
}
