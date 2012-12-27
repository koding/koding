package log

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"runtime"
	"strings"
)

type Entry struct {
	Service   string
	Host      string
	Level     int
	LevelName string
	Message   string
}

func (Entry *Entry) String() string {
	return fmt.Sprintf("%-6v %v", LEVEL_NAMES[Entry.Level], Entry.Message)
}

var LogToLoggly bool = false
var LogglyUrl string = "https://logs.loggly.com/inputs/a4b90ee3-0f30-4497-9840-483b6e6e60f0"
var Service string
var LogLevel int = 6
var Hostname string

func init() {
	Hostname, _ = os.Hostname()
}

func NewEntry(level int, message ...interface{}) *Entry {
	messageStrings := make([]string, len(message))
	for i, part := range message {
		if bytes, ok := part.([]byte); ok {
			messageStrings[i] = string(bytes)
		} else {
			messageStrings[i] = fmt.Sprint(part)
		}
	}
	return &Entry{
		Service:   Service,
		Host:      Hostname,
		Level:     level,
		LevelName: LEVEL_NAMES[level],
		Message:   strings.Join(messageStrings, "\n"),
	}
}

func Send(Entry interface{}) {
	if !LogToLoggly {
		fmt.Println(Entry)
		return
	}

	data, err := json.Marshal(Entry)
	if err != nil {
		fmt.Println("logger error: json.Marshal failed")
		return
	}

	_, err = http.Post(LogglyUrl, "application/json", bytes.NewReader(data))
	if err != nil {
		fmt.Println("logger error: http.Post failed")
		return
	}
}

func Log(level int, Entry ...interface{}) {
	if level > LogLevel {
		return
	}
	Send(NewEntry(level, Entry...))
}

const (
	EMERG  = 0
	ALERT  = 1
	CRIT   = 2
	ERR    = 3
	WARN   = 4
	NOTICE = 5
	INFO   = 6
	DEBUG  = 7
)

var LEVEL_NAMES = []string{"EMERG", "ALERT", "CRIT", "ERR", "WARN", "NOTICE", "INFO", "DEBUG"}

func Err(Entry ...interface{}) {
	Log(ERR, Entry...)
}

func Warn(Entry ...interface{}) {
	Log(WARN, Entry...)
}

func Info(Entry ...interface{}) {
	Log(INFO, Entry...)
}

func Debug(Entry ...interface{}) {
	Log(DEBUG, Entry...)
}

func LogError(err interface{}) {
	Entry := []interface{}{err}
	for i := 3; ; i++ {
		pc, file, line, ok := runtime.Caller(i)
		if !ok {
			break
		}
		fn := runtime.FuncForPC(pc)
		var name string
		if fn != nil {
			name = fn.Name()
		} else {
			name = "<unknown>"
		}
		Entry = append(Entry, fmt.Sprintf("at %s (%s:%d)", name, file, line))
	}
	Log(ERR, Entry...)
}

func RecoverAndLog() {
	err := recover()
	if err != nil {
		LogError(err)
	}
}
