package tsc

import (
	"bytes"
	"errors"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"text/template"
	"unicode"
	"unicode/utf8"
)

func nonil(err ...error) error {
	for _, err := range err {
		if err != nil {
			return err
		}
	}
	return nil
}

type Event struct {
	Name    string      // https://developer.github.com/webhooks/#events
	Payload interface{} // https://developer.github.com/v3/activity/events/types/
	Args    map[string]string
}

type Script struct {
	// ErrorLog specifies an optional logger for errors serving requests.
	// If nil, logging goes to os.Stderr via the log package's standard logger.
	ErrorLog *log.Logger

	OutputFunc func() io.Writer

	tmpl *template.Template
	args map[string]string
}

func New(file string, args []string) (*Script, error) {
	if len(args)&1 == 1 {
		return nil, errors.New("number of arguments for template script must be even")
	}
	sc := &Script{}
	if len(args) != 0 {
		sc.args = make(map[string]string)
		for i := 0; i < len(args); i += 2 {
			if len(args[i]) < 2 || args[i][0] != '-' {
				return nil, errors.New("invalid flag name: " + args[i])
			}
			r, n := utf8.DecodeRuneInString(args[i][1:])
			if r == utf8.RuneError {
				return nil, errors.New("invalid flag name: " + args[i])
			}
			sc.args[string(unicode.ToUpper(r))+args[i][1+n:]] = args[i+1]
		}
	}
	tmpl, err := template.New(filepath.Base(file)).Funcs(sc.funcs()).ParseFiles(file)
	if err != nil {
		return nil, err
	}
	sc.tmpl = tmpl
	return sc, nil
}

func (s *Script) Webhook(event string, payload interface{}) {
	w := s.output()
	err := s.tmpl.Execute(w, Event{Name: event, Payload: payload, Args: s.args})
	if c, ok := w.(io.Closer); ok {
		err = nonil(err, c.Close())
	}
	if err != nil {
		s.logf("ERROR template script error: %v", err)
	}
}

func (s *Script) funcs() template.FuncMap {
	return template.FuncMap{
		"env": func(s string) string {
			return os.Getenv(s)
		},
		"exec": func(cmd string, args ...string) (string, error) {
			out, err := exec.Command(cmd, args...).Output()
			return string(bytes.TrimSpace(out)), err
		},
		"log": func(v ...interface{}) string {
			if len(v) != 0 {
				s.log(v...)
			}
			return ""
		},
		"logf": func(format string, v ...interface{}) string {
			if format == "" {
				return ""
			}
			if len(v) == 0 {
				s.logf("%s", format)
			} else {
				s.logf(format, v...)
			}
			return ""
		},
	}
}

func (s *Script) output() io.Writer {
	if s.OutputFunc != nil {
		return s.OutputFunc()
	} else {
		return ioutil.Discard
	}
}

func (s *Script) logf(format string, v ...interface{}) {
	if s.ErrorLog != nil {
		s.ErrorLog.Printf(format, v...)
	} else {
		log.Printf(format, v...)
	}
}

func (s *Script) log(v ...interface{}) {
	if s.ErrorLog != nil {
		s.ErrorLog.Println(v...)
	} else {
		log.Println(v...)
	}
}
