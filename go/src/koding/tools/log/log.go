package log

import (
	"bytes"
	"encoding/json"
	"fmt"
	"koding/tools/config"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strings"
	"time"
)

var loggrSource string
var libratoSource string
var tags string

func Init(service string) {
	hostname, _ := os.Hostname()
	loggrSource = fmt.Sprintf("%s %d on %s", service, os.Getpid(), strings.Split(hostname, ".")[0])
	libratoSource = fmt.Sprintf("%s.%d:%s", service, os.Getpid(), hostname)
	tags = service + " " + config.Profile
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
				continue
			}
			dataStrings[i] = fmt.Sprint(part)
		}
		event.Add("data", strings.Join(dataStrings, "\n"))
	}
	return event
}

func Send(event url.Values) {
	if !config.Current.Loggr.Push {
		fmt.Printf("%-30s %s\n", "["+event.Get("tags")+"]", event.Get("text"))
		if event.Get("data") != "" {
			for _, line := range strings.Split(event.Get("data"), "\n") {
				fmt.Printf("%-30s %s\n", "", line)
			}
		}
		return
	}

	event.Add("apikey", config.Current.Loggr.ApiKey)
	resp, err := http.PostForm(config.Current.Loggr.Url, event)
	if err != nil || resp.StatusCode != http.StatusCreated {
		fmt.Println("logger error: http.PostForm failed.", resp, err)
		return
	}
	resp.Body.Close()
}

func Log(level int, text string, data ...interface{}) {
	if level == DEBUG && !config.LogDebug {
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
		name := "<unknown>"
		if fn := runtime.FuncForPC(pc); fn != nil {
			name = fn.Name()
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
	input  func() float64
}

var gauges = make([]Gauge, 0)
var GaugeChanges = make(chan func())

func init() {
	CreateGauge("goroutines", func() float64 {
		return float64(runtime.NumGoroutine())
	})
	CreateGauge("memory", func() float64 {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		return float64(m.Alloc)
	})
}

func CreateGauge(name string, input func() float64) {
	gauges = append(gauges, Gauge{name, 0, libratoSource, input})
}

func CreateCounterGauge(name string) func(int) {
	value := new(int)
	CreateGauge(name, func() float64 { return float64(*value) })
	return func(diff int) {
		GaugeChanges <- func() {
			*value += diff
		}
	}
}

func RunGaugesLoop() {
	go func() {
		reportInterval := time.Tick(time.Duration(config.Current.Librato.Interval) * time.Millisecond)
		for {
			select {
			case <-reportInterval:
				LogGauges()

			case change := <-GaugeChanges:
				change()
			}
		}
	}()
}

func LogGauges() {
	if !config.Current.Librato.Push {
		tagPrefix := "[gauges " + tags + "]"
		for _, gauge := range gauges {
			fmt.Printf("%-30s %s: %v\n", tagPrefix, gauge.Name, gauge.input())
			tagPrefix = ""
		}
		return
	}

	for _, gauge := range gauges {
		gauge.Value = gauge.input()
	}
	var event struct {
		Gauges []Gauge `json:"gauges"`
	}
	event.Gauges = gauges
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
	request.SetBasicAuth(config.Current.Librato.Email, config.Current.Librato.Token)
	request.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(request)
	if err != nil || resp.StatusCode != http.StatusOK {
		fmt.Println("logger error: http.Post failed.", resp, err)
		return
	}
	resp.Body.Close()
}
