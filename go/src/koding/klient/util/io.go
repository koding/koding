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
func PassTo(to dnode.Function, from io.Reader) error {
    buf := make([]byte, utf8.UTFMax)

    for {
        n, err := from.Read(buf)

        if n == 0 {
            if err != nil {
                return err
            }

            if err == io.EOF {
                return nil
            }

            continue
        }

        if e := to.Call(string(filterInvalidUTF8(buf[:n]))); e != nil {
            return e
        }

        if err != nil && err != io.EOF {
            return err
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
