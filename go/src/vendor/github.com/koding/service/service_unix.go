// Copyright 2015 Daniel Theophanes.
// Use of this source code is governed by a zlib-style
// license that can be found in the LICENSE file.

// +build linux darwin

package service

import (
	"bytes"
	"errors"
	"fmt"
	"log/syslog"
	"os/exec"
	"strings"
)

func newSysLogger(name string, errs chan<- error) (Logger, error) {
	w, err := syslog.New(syslog.LOG_INFO, name)
	if err != nil {
		return nil, err
	}
	return sysLogger{w, errs}, nil
}

type sysLogger struct {
	*syslog.Writer
	errs chan<- error
}

func (s sysLogger) send(err error) error {
	if err != nil && s.errs != nil {
		s.errs <- err
	}
	return err
}

func (s sysLogger) Error(v ...interface{}) error {
	return s.send(s.Writer.Err(fmt.Sprint(v...)))
}
func (s sysLogger) Warning(v ...interface{}) error {
	return s.send(s.Writer.Warning(fmt.Sprint(v...)))
}
func (s sysLogger) Info(v ...interface{}) error {
	return s.send(s.Writer.Info(fmt.Sprint(v...)))
}
func (s sysLogger) Errorf(format string, a ...interface{}) error {
	return s.send(s.Writer.Err(fmt.Sprintf(format, a...)))
}
func (s sysLogger) Warningf(format string, a ...interface{}) error {
	return s.send(s.Writer.Warning(fmt.Sprintf(format, a...)))
}
func (s sysLogger) Infof(format string, a ...interface{}) error {
	return s.send(s.Writer.Info(fmt.Sprintf(format, a...)))
}

var opNotPermitted = []byte("Operation not permitted")

func run(command string, arguments ...string) error {
	cmd := exec.Command(command, arguments...)
	out, err := cmd.CombinedOutput()

	// The following is a workaround for launchctl, which
	// gives success exit code when it fails with
	// insufficient permission error.
	if err == nil && bytes.Contains(out, opNotPermitted) {
		err = errors.New("exit status 1")
	}
	if err != nil {
		return fmt.Errorf(`"%s %s" failed: %s, %s`, command, strings.Join(arguments, " "), err, out)
	}
	return nil
}
