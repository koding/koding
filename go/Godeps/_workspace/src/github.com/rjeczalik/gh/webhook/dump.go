package webhook

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func now() string {
	return time.Now().UTC().Format("2006-01-02 at 03.04.05.000")
}

func nonil(err ...error) error {
	for _, err := range err {
		if err != nil {
			return err
		}
	}
	return nil
}

// Dumper is a helper handler, which wraps other http.Handler and dumps its
// requests' bodies to files in Dir directory and named after <event>-<delivery>.json,
// where:
//
//   - <event> is value of X-GitHub-Event header
//   - <delivery> is value of X-GitHub-Delivery header
//
// If headers are missing, current time is used instead.
type Dumper struct {
	Handler http.Handler // underlying handler
	Dir     string       // directory where files are written

	// ErrorLog specifies an optional logger for errors serving requests.
	// If nil, logging goes to os.Stderr via the log package's standard logger.
	ErrorLog *log.Logger

	// WriteFile specifies an optional file writer.
	// If nil, ioutil.WriteFile is used instead.
	WriteFile func(string, []byte, os.FileMode) error
}

// Dump creates new Dumper handler, which wraps a webhook handler and dumps each
// request's body to a file. It was added for *webhook.Handler in mind, but works
// on every generic http.Handler.
//
// If the destination directory is empty, Dump uses ioutil.TempDir instead.
// If the destination directory is a relative path, Dump uses filepath.Abs on it.
//
// If either of the above functions fails, Dump panics.
// If handler is a *webhook Handler and its ErrorLog field is non-nil, Dump uses
// it for logging.
func Dump(dir string, handler http.Handler) *Dumper {
	switch {
	case dir == "":
		name, err := ioutil.TempDir("", "webhook")
		if err != nil {
			panic(err)
		}
		dir = name
	default:
		name, err := filepath.Abs(dir)
		if err != nil {
			panic(err)
		}
		dir = name
		if err := os.MkdirAll(dir, 0755); err != nil {
			panic(err)
		}
	}
	d := &Dumper{
		Dir:     dir,
		Handler: handler,
	}
	if handler, ok := handler.(*Handler); ok {
		d.ErrorLog = handler.ErrorLog
	}
	return d
}

// ServeHTTP implements the http.Handler interface.
func (d *Dumper) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	buf := &bytes.Buffer{}
	req.Body = ioutil.NopCloser(io.TeeReader(req.Body, buf))
	d.Handler.ServeHTTP(w, req)
	go d.dump(req.Header.Get("X-GitHub-Event"), req.Header.Get("X-GitHub-Delivery"), buf)
}

func (d *Dumper) dump(event, delivery string, buf *bytes.Buffer) {
	var name string
	switch {
	case event != "" && delivery != "":
		name = filepath.Join(d.Dir, fmt.Sprintf("%s-%s.json", event, delivery))
	case event != "":
		name = filepath.Join(d.Dir, fmt.Sprintf("%s-%s.json", event, now()))
	default:
		name = filepath.Join(d.Dir, now())
	}
	var err error
	if d.WriteFile != nil {
		err = d.WriteFile(name, buf.Bytes(), 0644)
	} else {
		err = ioutil.WriteFile(name, buf.Bytes(), 0644)
	}
	switch err {
	case nil:
		d.logf("INFO %q: written file", name)
	default:
		d.logf("ERROR %q: error writing file: %v", name, err)
	}
}

func (d *Dumper) logf(format string, args ...interface{}) {
	if d.ErrorLog != nil {
		d.ErrorLog.Printf(format, args...)
	} else {
		log.Printf(format, args...)
	}
}
