package log

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strings"
)

var Service string
var Profile string
var Pid int
var Hostname string
var LogDebug bool = false
var LogToLoggr bool = false

func init() {
	Hostname, _ = os.Hostname()
	Pid = os.Getpid()
}

func NewEvent(level int, message ...interface{}) url.Values {
	messageStrings := make([]string, len(message))
	for i, part := range message {
		if bytes, ok := part.([]byte); ok {
			messageStrings[i] = string(bytes)
		} else {
			messageStrings[i] = fmt.Sprint(part)
		}
	}
	return url.Values{
		"source": {fmt.Sprintf("%s %d on %s", Service, Pid, Hostname)},
		"tags":   {LEVEL_TAGS[level] + " " + Service + " " + Profile},
		"text":   {messageStrings[0]},
		"data":   {strings.Join(messageStrings, "\n")},
	}
}

func Send(event url.Values) {
	if !LogToLoggr {
		fmt.Printf("[%s] %s\n", event.Get("tags"), event.Get("data"))
		return
	}

	event.Add("apikey", "eb65f620b72044118015d33b4177f805")
	_, err := http.PostForm("http://post.loggr.net/1/logs/koding/events", event)
	if err != nil {
		fmt.Println("logger error: http.PostForm failed")
		return
	}
}

func Log(level int, Entry ...interface{}) {
	if level == DEBUG && !LogDebug {
		return
	}
	Send(NewEvent(level, Entry...))
}

const (
	ERR = iota
	WARN
	INFO
	DEBUG
)

var LEVEL_TAGS = []string{"error", "warning", "info", "debug"}

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
