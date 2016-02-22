// Copyright 2013, Örjan Persson. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//+build !windows,!plan9

package logging

import "log/syslog"

// SyslogBackend is a simple logger to syslog backend. It automatically maps
// the internal log levels to appropriate syslog log levels.
type SyslogBackend struct {
	Writer *syslog.Writer
}

// NewSyslogBackend connects to the syslog daemon using UNIX sockets with the
// given prefix. If prefix is not given, the prefix will be derived from the
// launched command.
func NewSyslogBackend(prefix string, Priority syslog.Priority) (b *SyslogBackend, err error) {
	var w *syslog.Writer
	w, err = syslog.New(syslog.LOG_CRIT, prefix)
	return &SyslogBackend{w}, err
}

func (b *SyslogBackend) Log(level Level, calldepth int, rec *Record) error {
	switch level {
	case CRITICAL:
		return b.Writer.Crit(rec.Formatted())
	case ERROR:
		return b.Writer.Err(rec.Formatted())
	case WARNING:
		return b.Writer.Warning(rec.Formatted())
	case NOTICE:
		return b.Writer.Notice(rec.Formatted())
	case INFO:
		return b.Writer.Info(rec.Formatted())
	case DEBUG:
		return b.Writer.Debug(rec.Formatted())
	default:
	}
	panic("unhandled log level")
}
