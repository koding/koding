package logfetcher

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"

	"github.com/hpcloud/tail"
)

type Request struct {
	// Path is the path that log.tail will read from.
	Path string

	// Watch is a callback, to be given file data based on the log.tail configuration.
	Watch dnode.Function

	// Offset is the number of characters to return *relative to the end of file*! It
	// allows for behavior similar to `tail -fn X <path>`. The number should be
	// positive.

	// If an offset is provided, read the specified lines from the end of the file
	// return them to the callback.
	//
	// This is done separately from the tail watcher due to how the watchers are
	// shared among callbacks by path. To keep this optimization, we simply
	// read what we need from the file before subscribing this to the watcher.
	//
	// Note that this can inherently create race conditions in the form of missing
	// or duplicated lines between the file read and the log tail watcher, but
	// that is an acceptable compromise given the existing optimizations.
	LineOffset int
}

type PathTail struct {
	Tail      *tail.Tail
	Listeners map[string]dnode.Function
}

var (
	tailedMu    sync.Mutex // protects the followings
	tailedFiles = make(map[string]*PathTail)
)

func Tail(r *kite.Request) (interface{}, error) {
	var params *Request
	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	if !params.Watch.IsValid() {
		return nil, errors.New("watch argument is either not passed or it's not a function")
	}

	// unique ID for each new connection
	clientId := randomStringLength(16)

	// If an offset is specified, read the line offset and give it to the caller.
	// For a more detailed explanation about why we are doing it this way, see
	// the LineOffset docstring.
	if params.LineOffset > 0 {
		f, err := os.OpenFile(params.Path, os.O_RDONLY, 0600)
		if err != nil {
			return nil, err
		}

		lines, err := getOffsetLines(f, params.LineOffset)
		f.Close()

		if err != nil {
			return nil, err
		}

		for _, line := range lines {
			params.Watch.Call(line)
		}
	}

	tailedMu.Lock()
	p, ok := tailedFiles[params.Path]
	tailedMu.Unlock()
	if !ok {
		t, err := tail.TailFile(params.Path, tail.Config{
			Follow:    true,
			MustExist: true,
			Location: &tail.SeekInfo{
				Offset: 0,
				Whence: 2, // Relative to the end of file.
			},
		})
		if err != nil {
			return nil, err
		}

		p := &PathTail{
			Tail: t,
			Listeners: map[string]dnode.Function{
				clientId: params.Watch,
			},
		}

		tailedMu.Lock()
		tailedFiles[params.Path] = p
		tailedMu.Unlock()

		// start the tail only once for each path
		go func() {
			for line := range p.Tail.Lines {
				tailedMu.Lock()
				p, ok := tailedFiles[params.Path]
				tailedMu.Unlock()

				if !ok {
					continue
				}

				for _, listener := range p.Listeners {
					listener.Call(line.Text)
				}
			}

			// stop the tail all together if it somehow comes to here.
			tailedMu.Lock()
			p, ok := tailedFiles[params.Path]
			if !ok {
				tailedMu.Unlock()
				return
			}

			p.Tail.Stop()
			delete(tailedFiles, params.Path)
			tailedMu.Unlock()
		}()
	} else {
		// tailing is already started with a previous connection, just add this
		// new function so it's get notified too.
		p.Listeners[clientId] = params.Watch
	}

	r.Client.OnDisconnect(func() {
		tailedMu.Lock()
		p, ok := tailedFiles[params.Path]
		if ok {
			// delete the function for this connection
			delete(p.Listeners, clientId)

			// now check if there is any user left back. If we have removed
			// all users, we should also stop the watcher from watching the
			// path. So notify the watcher to stop watching the path and
			// also remove it from the callbacks map
			if len(p.Listeners) == 0 {
				p.Tail.Stop()
				delete(tailedFiles, params.Path)
			} else {
				tailedFiles[params.Path] = p // add back the decreased listener
			}
		}
		tailedMu.Unlock()
	})

	return true, nil
}

func getOffsetLines(f *os.File, requestedLines int) ([]string, error) {
	var (
		newLineChar   = byte('\n')
		foundNewLines int
		offset        int64
		start         int64
		// the byte slice that we read into
		b   = make([]byte, 1)
		err error
	)

	// Before we start looping, seek with an offset of zero, to identify if the
	// file has contents. If the start is zero, and we offset with zero,
	// then the start is the same as the end. Empty file, nothing we can do.
	start, err = f.Seek(0, 2)
	if err != nil {
		return nil, fmt.Errorf("getOffsetLines: Failed to seek. err:%s", err)
	}
	if start == 0 {
		return []string{}, nil
	}

	// Loop through the file, looking for all of our newlines.
	for foundNewLines < requestedLines {
		offset--

		start, err = f.Seek(offset, 2)
		if err != nil {
			return nil, fmt.Errorf("getOffsetLines: Failed to seek newline. err:%s", err)
		}

		// if we're at the start of the file, we can't find anymore newlines. Return
		// what we have.
		if start == 0 {
			break
		}

		_, err = f.ReadAt(b, start)
		if err != nil {
			return nil, fmt.Errorf("getOffsetLines: Failed to read newline. err:%s", err)
		}

		// If the char is a newline, and not at the very end of the file, record the
		// newline count. For a further explanation about why we aren't counting
		// the last newline on the file, see the docstring here we trim the last
		// element of the bytes array.
		if b[0] == newLineChar && offset != -1 {
			foundNewLines++
		}
	}

	// Make offset positive, because the total chars offset is the total chars we want
	// to read.
	matchedCharLen := offset * -1
	b = make([]byte, matchedCharLen)
	_, err = f.ReadAt(b, start)
	if err != nil && err != io.EOF {
		return nil, fmt.Errorf("getOffsetLines: Failed to read lines. err:%s", err)
	}

	// If the last char of the file was a newline, the last element in the lines
	// slice will be empty. To keep a consistent UX with the way tail library
	// returns newlines, we should trim this char.
	if b[len(b)-1] == newLineChar {
		b = b[:len(b)-1]
	}

	lines := strings.Split(string(b), string(newLineChar))

	// If we are not at the beginning of the file, then the first character is a
	// newline, one more line than the user requested. So trim that off.
	if start > 0 {
		return lines[1:], nil
	}

	return lines, nil
}

// randomStringLength is used to generate a session_id.
func randomStringLength(length int) string {
	size := (length * 6 / 8) + 1
	r := make([]byte, size)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)[:length]
}
