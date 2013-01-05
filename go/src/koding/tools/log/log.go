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

func NewEvent(level int, text string, data ...interface{}) url.Values {
	event := url.Values{
		"source": {fmt.Sprintf("%s %d on %s", Service, Pid, Hostname)},
		"tags":   {LEVEL_TAGS[level] + " " + Service + " " + Profile},
		"text":   {text},
	}
	if len(data) != 0 {
		dataStrings := make([]string, len(data))
		for i, part := range data {
			if bytes, ok := part.([]byte); ok {
				dataStrings[i] = string(bytes)
			} else {
				dataStrings[i] = fmt.Sprint(part)
			}
		}
		event.Add("data", strings.Join(dataStrings, "\n"))
	}
	return event
}

func Send(event url.Values) {
	if !LogToLoggr {
		tagPrefix := "[" + event.Get("tags") + "] "
		data := event.Get("data")
		if data != "" {
			linePrefix := "\n" + strings.Repeat(" ", len(tagPrefix))
			data = linePrefix + strings.Replace(data, "\n", linePrefix, -1)
		}
		fmt.Println(tagPrefix + event.Get("text") + data)
		return
	}

	event.Add("apikey", "eb65f620b72044118015d33b4177f805")
	_, err := http.PostForm("http://post.loggr.net/1/logs/koding/events", event)
	if err != nil {
		fmt.Println("logger error: http.PostForm failed")
		return
	}
}

func Log(level int, text string, data ...interface{}) {
	if level == DEBUG && !LogDebug {
		return
	}
	Send(NewEvent(level, text, data...))
}

const (
	ERR = iota
	WARN
	INFO
	DEBUG
)

var LEVEL_TAGS = []string{"error", "warning", "info", "debug"}

func Err(text string, data ...interface{}) {
	Log(ERR, text, data...)
}

func Warn(text string, data ...interface{}) {
	Log(WARN, text, data...)
}

func Info(text string, data ...interface{}) {
	Log(INFO, text, data...)
}

func Debug(text string, data ...interface{}) {
	Log(DEBUG, text, data...)
}

func LogError(err interface{}, stackOffset int) {
	data := make([]interface{}, 0)
	for i := 1 + stackOffset; ; i++ {
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
		data = append(data, fmt.Sprintf("at %s (%s:%d)", name, file, line))
	}
	Log(ERR, fmt.Sprint(err), data...)
}

func RecoverAndLog() {
	err := recover()
	if err != nil {
		LogError(err, 2)
	}
}
