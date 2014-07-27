package helper

import (
	slog "log"
	"log/syslog"
	"os"
	"runtime"

	"github.com/koding/logging"
	kodingmetrics "github.com/koding/metrics"
	"github.com/rcrowley/go-metrics"
)

func CreateMetrics(appName string, log logging.Logger, outputMetrics bool) *kodingmetrics.Metrics {
	metric := kodingmetrics.New(appName)

	// if outputMetrics, do print output to the console
	if outputMetrics {
		// change those loggers
		// https://github.com/rcrowley/go-metrics/blob/37df06ff62a7d8b4473b48d355008c838da87561/log.go
		// get those numbers from config
		go metrics.Log(metric.Registry, 1e10, slog.New(os.Stderr, "metrics: ", slog.Lmicroseconds))
	}

	// for Mac
	syslogPath := "/var/run/syslog"
	if runtime.GOOS != "darwin" {
		// for linux
		syslogPath = "/dev/log"
	}

	w, err := syslog.Dial("unixgram", syslogPath, syslog.LOG_INFO, "socialapi-metrics")
	if err != nil {
		log.Error("err while initing syslog for metrics, metrics wont be in the syslog %s", err.Error())
	} else {
		go metrics.Syslog(metric.Registry, 1e10, w)
	}

	return metric
}
