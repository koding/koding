package logger

import (
	"fmt"
	"github.com/op/go-logging"
	"koding/tools/config"
	stdlog "log"
	"os"
	"os/exec"
	"strings"
	"time"
)

var loggingLevel logging.Level

var nameToLevelMapping = map[string]logging.Level{
	"debug":   logging.DEBUG,
	"warning": logging.WARNING,
	"error":   logging.ERROR,
}

// Get logging level from config file and find the appropriate logging.Level
// from string.
func init() {
	var exists bool
	var logLevelString = config.Current.Neo4j.LogLevel

	loggingLevel, exists = nameToLevelMapping[logLevelString]
	if !exists {
		loggingLevel = logging.DEBUG
	}
}

func New(name string) *logging.Logger {
	logging.SetFormatter(logging.MustStringFormatter("[%{level:.8s}] - %{message}"))

	var logBackend = logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	var syslogBackend, err = logging.NewSyslogBackend("")
	if err != nil {
		panic(err)
	}

	logging.SetBackend(logBackend, syslogBackend)

	// Set logging level based on value in config.
	logging.SetLevel(loggingLevel, name)

	return logging.MustGetLogger(name)
}

//----------------------------------------------------------
// Gauges. Copied over from koding/tool/log
//----------------------------------------------------------

type Unit string

type Gauge struct {
	Name   string  `json:"name"`
	Value  float64 `json:"value"`
	Time   int64   `json:"measure_time"`
	Source string  `json:"source"`
	unit   Unit
	input  func() float64
}

const ISO8601 = "2006-01-02T15:04:05.000"

var gauges = make([]*Gauge, 0)
var GaugeChanges = make(chan func())
var tags string
var hostname string

func CreateGauge(name string, unit Unit, input func() float64) {
	gauges = append(gauges, &Gauge{name, 0, 0, "", unit, input})
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

var interval = 60000

func RunGaugesLoop() {
	reportTrigger := make(chan int64)
	go func() {
		reportInterval := int64(interval) / 1000
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
			case change := <-GaugeChanges:
				change()
			}
		}
	}()
}

func LogGauges(reportTime int64) {
	if !config.Current.Opsview.Push {
		indent := strings.Repeat(" ", len(ISO8601)+1)
		stdlog.Printf("%s [gauges %s]\n", time.Now().Format(ISO8601), tags)

		for _, gauge := range gauges {
			stdlog.Printf("%s%s: %v\n", indent, gauge.Name, gauge.input())
		}
		return
	}

	for _, gauge := range gauges {
		gauge.Value = gauge.input()
		gauge.Time = reportTime
	}

	if config.Current.Opsview.Push {
		entries := make([]string, len(gauges))
		for i, gauge := range gauges {
			entries[i] = fmt.Sprintf("%s=%f%s", gauge.Name, gauge.Value, gauge.unit)
		}
		cmd := exec.Command("/usr/local/nagios/bin/send_nsca", "-H", config.Current.Opsview.Host, "-c", "/usr/local/nagios/etc/send_nsca.cfg")
		cmd.Stdin = strings.NewReader(hostname + "\tGauges\t0\tGauge Data Sent|" + strings.Join(entries, " ") + "\n")
		if out, err := cmd.CombinedOutput(); err != nil {
			stdlog.Printf("logger error: send_nsca failed.\n%v\n%v\n", err, string(out))
		}
	}
}
