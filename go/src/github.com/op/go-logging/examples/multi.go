// Copyright 2013 Örjan Persson. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	stdlog "log"
	"os"

	"github.com/op/go-logging"
)

var log = logging.MustGetLogger("test")

type Password string

func (p Password) Redacted() interface{} {
	return logging.Redact(string(p))
}

func main() {
	// Customize the output format
	logging.SetFormatter(logging.MustStringFormatter("▶ %{level:.1s} 0x%{id:x} %{message}"))

	// Setup one stdout and one syslog backend.
	logBackend := logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	syslogBackend, err := logging.NewSyslogBackend("")
	if err != nil {
		log.Fatal(err)
	}

	// Combine them both into one logging backend.
	logging.SetBackend(logBackend, syslogBackend)

	// Run one with debug setup for "test" and one with error.
	for _, level := range []logging.Level{logging.DEBUG, logging.ERROR} {
		logging.SetLevel(level, "test")

		log.Critical("crit")
		log.Error("err")
		log.Warning("warning")
		log.Notice("notice")
		log.Info("info")
		log.Debug("debug %s", Password("secret"))
	}
}
