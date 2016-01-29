// +build !windows,!plan9

package logging

import (
	"log/syslog"
)

///////////////////
//               //
// SyslogHandler //
//               //
///////////////////

// SyslogHandler sends the logging output to syslog.
type SyslogHandler struct {
	*BaseHandler
	w *syslog.Writer
}

func NewSyslogHandler(tag string) (*SyslogHandler, error) {
	// Priority in New constructor is not important here because we
	// do not use w.Write() directly.
	w, err := syslog.New(syslog.LOG_INFO|syslog.LOG_USER, tag)
	if err != nil {
		return nil, err
	}
	return &SyslogHandler{
		BaseHandler: NewBaseHandler(),
		w:           w,
	}, nil
}

func (b *SyslogHandler) Handle(rec *Record) {
	message := b.BaseHandler.FilterAndFormat(rec)
	if message == "" {
		return
	}

	var fn func(string) error
	switch rec.Level {
	case CRITICAL:
		fn = b.w.Crit
	case ERROR:
		fn = b.w.Err
	case WARNING:
		fn = b.w.Warning
	case NOTICE:
		fn = b.w.Notice
	case INFO:
		fn = b.w.Info
	case DEBUG:
		fn = b.w.Debug
	}
	fn(message)
}

func (b *SyslogHandler) Close() {
	b.w.Close()
}
