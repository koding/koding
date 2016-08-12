// Package systemd/journal implements a client for the journal system. package journal
package journal

import (
	"encoding/binary"
	"errors"
	"fmt"
	"net"
	"runtime"
	"strings"
	"sync"
)

// The path to the journald socket.
const systemdSocket = "/run/systemd/journal/socket"

var errMissingEquals = errors.New("journal: missing '=' in message")

func grow(s []byte) []byte {
	buf := make([]byte, len(s), 8+len(s)+len(s)/4)
	copy(buf, s)
	return buf
}

type Handle struct {
	path string
	conn *net.UnixConn
	lock sync.Mutex
}

var defaultHandle = &Handle{path: systemdSocket}

func Printf(format string, args ...interface{}) error { return defaultHandle.Printf(format, args...) }

// Send logs a sequence of strings in the form "key=value".
func Send(args ...string) error { return defaultHandle.Send(args...) }

// See standard field names in systemd.journal-fields(7).
func (h *Handle) Printf(format string, args ...interface{}) error {
	pc, file, line, _ := runtime.Caller(1)
	funcname := runtime.FuncForPC(pc).Name()

	return h.Send("CODE_FILE="+file,
		fmt.Sprintf("CODE_LINE=%d", line),
		"CODE_FUNC="+funcname,
		fmt.Sprintf("MESSAGE="+format, args...),
	)
}

func (h *Handle) Send(args ...string) error {
	const maxbufsize = 32 << 10

	// Todo. Implement a zero copy version.
	size := int64(0)
	for _, s := range args {
		size += int64(len(s) + 1)
	}
	if size > maxbufsize {
		return h.sendLarge(args...)
	}

	// Build a buffer whose lines are the input strings.
	buf := make([]byte, 0, size)
	for _, s := range args {
		// Validate.
		i := strings.IndexRune(s, '=')
		j := strings.IndexRune(s, '\n')
		if i < 0 {
			return errMissingEquals
		}
		if 0 <= j && j < i {
			return errMissingEquals
		}

		if j >= 0 {
			// Multiline message: key + '\n' + 64-bit LE length + msg  + '\n'
			buf = append(buf, s[:i]...)
			buf = append(buf, '\n')
			msg := s[i+1:]
			if cap(buf) < len(buf)+8 {
				buf = grow(buf)
			}
			binary.LittleEndian.PutUint64(buf[len(buf):len(buf)+8], uint64(len(msg)))
			buf = append(buf[:len(buf)+8], msg...)
			buf = append(buf, '\n')
			fmt.Printf("%q\n", buf)
		} else {
			// Simple message.
			buf = append(buf, s...)
			buf = append(buf, '\n')
		}
	}
	return h.send(buf)
}

func (h *Handle) send(buf []byte) error {
	var err error

	h.lock.Lock()
	defer h.lock.Unlock()

	jaddr := &net.UnixAddr{Net: "unixgram", Name: h.path}
	if h.conn == nil {
		h.conn, err = net.DialUnix("unixgram", nil, jaddr)
		if err != nil {
			return err
		}
	}

	n, _, err := h.conn.WriteMsgUnix(buf, nil, jaddr)
	if n == 0 {
		return h.sendLargeBuf(buf)
	}
	return err
}

func (h *Handle) sendLargeBuf(msg []byte) error { panic("not implemented") }

func (h *Handle) sendLarge(args ...string) error { panic("not implemented") }
