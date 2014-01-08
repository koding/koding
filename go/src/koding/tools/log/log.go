package log

import (
	"bytes"
	"encoding/json"
	"fmt"
	"koding/tools/config"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

type Gauge struct {
	Name   string  `json:"name"`
	Value  float64 `json:"value"`
	Time   int64   `json:"measure_time"`
	Source string  `json:"source"`
	unit   Unit
	input  func() float64
}

type Unit string

const (
	NoUnit     = Unit("")
	Seconds    = Unit("s")
	Percentage = Unit("%")
	Bytes      = Unit("B")
)

type Event struct {
	Level    int
	Text     string
	Data     []interface{}
	Exit     bool
	ExitCode int
}

var hostname string
var loggrSource string
var libratoSource string
var tags string
var currentSecond int64
var logCounter int
var MaxPerSecond int = 10
var sendChannel = make(chan *Event, 1000)

var gauges = make([]*Gauge, 0)
var GaugeChanges = make(chan func())

func Init(service string) {
	hostname, _ := os.Hostname()
	loggrSource = fmt.Sprintf("%s %d on %s", service, os.Getpid(), strings.Split(hostname, ".")[0])
	libratoSource = fmt.Sprintf("%s.%d:%s", service, os.Getpid(), hostname)
	tags = service + " " + config.Profile

	CreateGauge("goroutines", NoUnit, func() float64 {
		return float64(runtime.NumGoroutine())
	})
	CreateGauge("memory", Bytes, func() float64 {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		return float64(m.Alloc)
	})

	if config.Current.Loggr.Push {
		e := Event{Level: INFO, Text: "Logging to Loggr instead of console."}
		fmt.Print(e.String())
	}

	go func() {
		client := &http.Client{}
		for event := range sendChannel {
			if event.Exit {
				os.Exit(event.ExitCode)
			}

			if !config.Current.Loggr.Push || config.LogDebug {
				fmt.Print(event.String())
			}

			if !config.Current.Loggr.Push || event.Level == DEBUG {
				continue
			}

			values := url.Values{
				"source": {loggrSource},
				"tags":   {LEVEL_TAGS[event.Level] + " " + tags},
				"text":   {event.Text},
				"apikey": {config.Current.Loggr.ApiKey},
			}
			if len(event.Data) != 0 {
				dataStrings := make([]string, len(event.Data))
				for i, part := range event.Data {
					if bytes, ok := part.([]byte); ok {
						dataStrings[i] = string(bytes)
						continue
					}
					dataStrings[i] = fmt.Sprint(part)
				}
				values.Add("data", strings.Join(dataStrings, "\n"))
			}

			resp, err := client.PostForm(config.Current.Loggr.Url, values)
			if err != nil || resp.StatusCode != http.StatusCreated {
				fmt.Printf("logger error: http.PostForm failed.\n%v\n%v\n%v\n", event, resp, err)
			}
			if resp != nil && resp.Body != nil {
				resp.Body.Close()
			}
		}
	}()
}

func Send(event *Event) {
	select {
	case sendChannel <- event:
		// successful
	default:
		fmt.Println("logger error: sendChannel is full.")
	}
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
			Send(&Event{Level: ERR, Text: fmt.Sprintf("Dropping log events because of more than %d in one second.", MaxPerSecond)})
		}
		return
	}

	Send(&Event{Level: level, Text: text, Data: data})
}

func SendLogsAndExit(code int) {
	Send(&Event{Exit: true, ExitCode: code})
	time.Sleep(time.Hour) // wait for exit
}

const ISO8601 = "2006-01-02T15:04:05.000"

func (e Event) String() string {
	indent := strings.Repeat(" ", len(ISO8601)+1)

	s := time.Now().Format(ISO8601) + " [" + LEVEL_TAGS[e.Level] + " " + tags + "]\n"
	s += indent + e.Text + "\n"

	for _, part := range e.Data {
		if bytes, ok := part.([]byte); ok {
			s += indent + string(bytes) + "\n"
			continue
		}
		s += indent + fmt.Sprint(part) + "\n"
	}

	return s
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

func Errf(format string, data ...interface{}) {
	Log(ERR, fmt.Sprintf(format, data...))
}

func Warn(text string, data ...interface{}) {
	Log(WARN, text, data...)
}

func Warnf(format string, data ...interface{}) {
	Log(WARN, fmt.Sprintf(format, data...))
}

func Info(text string, data ...interface{}) {
	Log(INFO, text, data...)
}

func Infof(format string, data ...interface{}) {
	Log(INFO, fmt.Sprintf(format, data...))
}

func Debug(text string, data ...interface{}) {
	Log(DEBUG, text, data...)
}

func Debugf(format string, data ...interface{}) {
	Log(DEBUG, fmt.Sprintf(format, data...))
}

func LogError(err interface{}, stackOffset int, additionalData ...interface{}) {
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
	data = append(data, additionalData...)
	Log(ERR, fmt.Sprint(err), data...)
}

func RecoverAndLog() {
	if err := recover(); err != nil {
		LogError(err, 2)
	}
}

func CreateGauge(name string, unit Unit, input func() float64) {
	gauges = append(gauges, &Gauge{name, 0, 0, libratoSource, unit, input})
}

func CreateCounterGauge(name string, unit Unit, resetOnReport bool) func(int) {
	value := new(int)
	CreateGauge(name, unit, func() float64 {
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
			// case reportTime := <-reportTrigger:
			// 	LogGauges(reportTime)
			case change := <-GaugeChanges:
				change()
			}
		}
	}()
}

func LogGauges(reportTime int64) {
	if !config.Current.Librato.Push && !config.Current.Opsview.Push {
		indent := strings.Repeat(" ", len(ISO8601)+1)
		fmt.Printf("%s [gauges %s]\n", time.Now().Format(ISO8601), tags)
		for _, gauge := range gauges {
			fmt.Printf("%s%s: %v\n", indent, gauge.Name, gauge.input())
		}
		return
	}

	for _, gauge := range gauges {
		gauge.Value = gauge.input()
		gauge.Time = reportTime
	}

	if config.Current.Librato.Push {
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

	if config.Current.Opsview.Push {
		entries := make([]string, len(gauges))
		for i, gauge := range gauges {
			entries[i] = fmt.Sprintf("%s=%f%s", gauge.Name, gauge.Value, gauge.unit)
		}
		cmd := exec.Command("/usr/local/nagios/bin/send_nsca", "-H", config.Current.Opsview.Host, "-c", "/usr/local/nagios/etc/send_nsca.cfg")
		cmd.Stdin = strings.NewReader(hostname + "\tGauges\t0\tGauge Data Sent|" + strings.Join(entries, " ") + "\n")
		if out, err := cmd.CombinedOutput(); err != nil {
			fmt.Printf("logger error: send_nsca failed.\n%v\n%v\n", err, string(out))
		}
	}
}
