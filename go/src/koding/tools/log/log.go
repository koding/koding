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

type Gauge struct {
	Name   string  `json:"name"`
	Value  float64 `json:"value"`
	Time   int64   `json:"measure_time"`
	Source string  `json:"source"`
	input  func() float64
}

var loggrSource string
var libratoSource string
var tags string
var currentSecond int64
var logCounter int
var MaxPerSecond int = 10
var sendChannel = make(chan url.Values, 1000)

var gauges = make([]*Gauge, 0)
var GaugeChanges = make(chan func())

func Init(service string) {
	hostname, _ := os.Hostname()
	loggrSource = fmt.Sprintf("%s %d on %s", service, os.Getpid(), strings.Split(hostname, ".")[0])
	libratoSource = fmt.Sprintf("%s.%d:%s", service, os.Getpid(), hostname)
	tags = service + " " + config.Profile

	CreateGauge("goroutines", func() float64 {
		return float64(runtime.NumGoroutine())
	})
	CreateGauge("memory", func() float64 {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		return float64(m.Alloc)
	})

	go func() {
		for event := range sendChannel {
			if !config.Current.Loggr.Push {
				fmt.Printf("%-30s %s\n", "["+event.Get("tags")+"]", event.Get("text"))
				if event.Get("data") != "" {
					for _, line := range strings.Split(event.Get("data"), "\n") {
						fmt.Printf("%-30s %s\n", "", line)
					}
				}
				continue
			}

			event.Add("apikey", config.Current.Loggr.ApiKey)
			resp, err := http.PostForm(config.Current.Loggr.Url, event)
			if err != nil || resp.StatusCode != http.StatusCreated {
				fmt.Printf("logger error: http.PostForm failed.\n%v\n%v\n%v\n", event, resp, err)
			}
			if resp != nil && resp.Body != nil {
				resp.Body.Close()
			}
		}
	}()
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

func Log(level int, text string, data ...interface{}) {
	if level == DEBUG && !config.LogDebug {
		return
	}

	t := time.Now().Unix()
	if currentSecond != t {
		currentSecond = t
		logCounter = 0
	}
	logCounter += 1
	if !config.LogDebug && MaxPerSecond > 0 && logCounter > MaxPerSecond {
		if logCounter == MaxPerSecond+1 {
			sendChannel <- NewEvent(ERR, fmt.Sprintf("Dropping log events because of more than %d in one second.", MaxPerSecond))
		}
		return
	}

	sendChannel <- NewEvent(level, text, data...)
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
	if err := recover(); err != nil {
		LogError(err, 2)
	}
}

func CreateGauge(name string, input func() float64) {
	gauges = append(gauges, &Gauge{name, 0, 0, libratoSource, input})
}

func CreateCounterGauge(name string, resetOnReport bool) func(int) {
	value := new(int)
	CreateGauge(name, func() float64 {
		v := *value
		if resetOnReport {
			*value = 0
		}
		return float64(v)
	})
	return func(diff int) {
		GaugeChanges <- func() {
			*value += diff
		}
	}
}

func RunGaugesLoop() {
	reportTrigger := make(chan int64)
	go func() {
		reportInterval := int64(config.Current.Librato.Interval) / 1000
		nextReportTime := time.Now().Unix() / reportInterval * reportInterval
		for {
			nextReportTime += reportInterval
			time.Sleep(time.Duration(nextReportTime-time.Now().Unix()) * time.Second)
			reportTrigger <- nextReportTime
		}
	}()
	go func() {
		for {
			select {
			case reportTime := <-reportTrigger:
				LogGauges(reportTime)

			case change := <-GaugeChanges:
				change()
			}
		}
	}()
}

func LogGauges(reportTime int64) {
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
		gauge.Time = reportTime
	}
	var event struct {
		Gauges []*Gauge `json:"gauges"`
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
		fmt.Printf("logger error: http.Post failed.\n%v\n%v\n%v\n", string(b), resp, err)
	}
	if resp != nil && resp.Body != nil {
		resp.Body.Close()
	}
}
