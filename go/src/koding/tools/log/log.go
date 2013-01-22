package log

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strings"
)

var loggrSource string
var libratoSource string
var tags string
var LogDebug bool = false
var LogToCloud bool = false

func Init(service, profile string) {
	hostname, _ := os.Hostname()
	loggrSource = fmt.Sprintf("%s %d on %s", service, os.Getpid(), strings.Split(hostname, ".")[0])
	libratoSource = fmt.Sprintf("%s.%d:%s", service, os.Getpid(), hostname)
	tags = service + " " + profile
}

func NewEvent(level int, text string, data ...interface{}) url.Values {
	event := url.Values{
		"source": {loggrSource},
		"tags":   {LEVEL_TAGS[level] + " " + tags},
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
	if !LogToCloud {
		fmt.Printf("%-30s %s\n", "["+event.Get("tags")+"]", event.Get("text"))
		if event.Get("data") != "" {
			for _, line := range strings.Split(event.Get("data"), "\n") {
				fmt.Printf("%-30s %s\n", "", line)
			}
		}
		return
	}

	event.Add("apikey", "eb65f620b72044118015d33b4177f805")
	resp, err := http.PostForm("http://post.loggr.net/1/logs/koding/events", event)
	if err != nil || resp.StatusCode != http.StatusCreated {
		fmt.Println("logger error: http.PostForm failed.", resp, err)
		return
	}
	resp.Body.Close()
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

type Gauge struct {
	Name   string  `json:"name"`
	Value  float64 `json:"value"`
	Source string  `json:"source"`
}

func Gauges(gauges map[string]float64) {
	if !LogToCloud {
		tagPrefix := "[gauges " + tags + "]"
		for name, value := range gauges {
			fmt.Printf("%-30s %s: %v\n", tagPrefix, name, value)
			tagPrefix = ""
		}
		return
	}

	var event struct {
		Gauges []Gauge `json:"gauges"`
	}
	event.Gauges = make([]Gauge, 0, len(gauges))
	for name, value := range gauges {
		event.Gauges = append(event.Gauges, Gauge{name, value, libratoSource})
	}
	b, err := json.Marshal(event)
	if err != nil {
		fmt.Println("logger error: json.Marshal failed.", err)
		return
	}

	request, err := http.NewRequest("POST", "https://metrics-api.librato.com/v1/metrics", bytes.NewReader(b))
	if err != nil {
		fmt.Println("logger error: http.NewRequest failed.", err)
		return
	}
	request.SetBasicAuth("devrim@koding.com", "3f79eeb972c201a6a8d3461d4dc5395d3a1423f4b7a2764ec140572e70a7bce0")
	request.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(request)
	if err != nil || resp.StatusCode != http.StatusOK {
		fmt.Println("logger error: http.Post failed.", resp, err)
		return
	}
	resp.Body.Close()
}
