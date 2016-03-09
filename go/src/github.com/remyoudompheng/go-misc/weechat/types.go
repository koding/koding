package weechat

import (
	"log"
	"time"
)

var DEBUG = true

func debugf(format string, args ...interface{}) {
	if DEBUG {
		log.Printf(format, args...)
	}
}

type Nick struct {
	Group   byte   "group"
	Visible byte   "visible"
	Name    string "name"
	Prefix  string "prefix"

	Buffer uintptr "ptr:buffer"
	Self   uintptr "ptr:nicklist_item"
}

func (n Nick) String() string {
	return n.Prefix + n.Name
}

type Buffer struct {
	Name      string "name"
	ShortName string "short_name"
	FullName  string "full_name"
	Title     string "title"

	Self uintptr "ptr:buffer"
	Prev uintptr "prev_buffer"
	Next uintptr "next_buffer"
}

type Line struct {
	Self uintptr "ptr:line"
}

type LineData struct {
	Date        time.Time "date"
	DatePrinted time.Time "date_printed"
	TimeString  string    "str_time"
	Prefix      string    "prefix"
	Message     string    "message"

	RefreshNeeded byte "refresh_needed"
	Displayed     byte "displayed"
	Highlight     byte "highlight"

	Buffer uintptr "ptr:buffer"
	Lines  uintptr "ptr:lines"
	Line   uintptr "ptr:line"
	Self   uintptr "ptr:line_data"
}

func (l *LineData) Clean() {
	l.Prefix = cleanColor(l.Prefix)
	l.Message = cleanColor(l.Message)
	l.TimeString = cleanColor(l.TimeString)
}

func cleanColor(s string) string {
	buf := make([]byte, 0, len(s))
	for i := 0; i < len(s); i++ {
		if s[i] == '\x19' {
			// weechat color code.
			switch s[i+1] {
			case 'F', 'B':
				// fore/back-ground color: F## or B##
				i += 3
			case '*':
				// *##,##
				i += 6
			default:
				// ##
				i += 2
			}
		} else {
			buf = append(buf, s[i])
		}
	}
	return string(buf)
}
