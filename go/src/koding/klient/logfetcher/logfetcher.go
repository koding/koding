package logfetcher

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"sync"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"

	"github.com/hpcloud/tail"
)

// defaultOffsetChunkSize is the buffersize that the logfetcher will use when
// reading the offsets.
const defaultOffsetChunkSize int64 = 4096

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

		lines, err := GetOffsetLines(f, defaultOffsetChunkSize, params.LineOffset)
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
			defer tailedMu.Unlock()

			p, ok := tailedFiles[params.Path]
			if !ok {
				return
			}

			p.Tail.Stop()
			delete(tailedFiles, params.Path)
		}()
	} else {
		// tailing is already started with a previous connection, just add this
		// new function so it's get notified too.
		p.Listeners[clientId] = params.Watch
	}

	r.Client.OnDisconnect(func() {
		tailedMu.Lock()
		defer tailedMu.Unlock()

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
			}
		}
	})

	return true, nil
}

func GetOffsetLines(f *os.File, chunkSize int64, requestedLines int) ([]string, error) {
	var (
		newLineChar = byte('\n')
		foundLines  []string
		offset      int64
		start       int64
		// A partial, buffered line.
		bufLine string
	)

	// Before we start looping, seek with an offset of zero, to identify if the
	// file has contents. If the start is zero, and we offset with zero,
	// then the start is the same as the end. Empty file, nothing we can do.
	start, err := f.Seek(0, 2)
	if err != nil {
		return nil, fmt.Errorf("GetOffsetLines: Failed to seek. err:%s", err)
	}
	if start == 0 {
		return nil, nil
	}

	// At this point, Start represents how long the file is. If chunkSize is bigger
	// than that, we're not going to be able to offset by such a large amount.
	//
	// So, we reduce the chunkSize to the size of the file.
	if chunkSize > start {
		chunkSize = start
	}

	// the byte slice that we read into
	b := make([]byte, chunkSize)

	// Loop through the file, looking for all of our newlines.
	for len(foundLines) < requestedLines {
		offset -= chunkSize

		start, err = f.Seek(offset, 2)
		if err != nil {
			return nil, fmt.Errorf("getOffsetLines: Failed to seek newline. err:%s", err)
		}

		if _, err = f.ReadAt(b, start); err != nil {
			return nil, fmt.Errorf("getOffsetLines: Failed to read newline. err:%s", err)
		}

		chunkEnd := chunkSize
		for i := chunkSize - 1; i >= 0 && len(foundLines) < requestedLines; i-- {
			if b[i] == newLineChar {
				// If the offset is negative chunksize, and i is chunksize sub one,
				// then this is the very first character we've looked at. Ignore this
				// newline.
				//
				// This is to match behavior with the existing tail library.
				if offset == -chunkSize && i == chunkSize-1 {
					chunkEnd = i
					continue
				}

				// Set chunkBegin to the location *after* the newline. This lets us trim
				// the newline.
				chunkBegin := i + 1

				// If the first char in a chunk is a newline, chunkBegin (due to trimming
				// above) will be bigger than chunkEnd. So, change the beginning to be
				// the same as the end - this also trims the newline.
				if chunkBegin > chunkEnd {
					chunkBegin = chunkEnd
				}

				line := string(b[chunkBegin:chunkEnd])
				chunkEnd = i

				// Combine a previous chunks line, with the current line.
				if len(bufLine) > 0 {
					line = line + bufLine
					bufLine = ""
				}

				// Since we found a line, prepend it to the foundLines slice
				foundLines = append(
					[]string{line},
					foundLines...,
				)
			}
		}

		if chunkEnd > 0 {
			bufLine = string(b[:chunkEnd]) + bufLine
		}

		// if we're at the start of the file, we can't find anymore newlines. Return
		// what we have.
		if start == 0 {
			break
		}
	}

	// If we found less lines than requested, prepend any existing data to the lines
	// list.
	if len(foundLines) < requestedLines && len(bufLine) > 0 {
		foundLines = append(
			[]string{bufLine},
			foundLines...,
		)
	}

	return foundLines, nil
}

// randomStringLength is used to generate a session_id.
func randomStringLength(length int) string {
	size := (length * 6 / 8) + 1
	r := make([]byte, size)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)[:length]
}
