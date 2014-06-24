package db

import (
	"fmt"
	"regexp"
	"time"

	"github.com/koding/logging"
)

func NewGormLogger(log logging.Logger) *gormLogger {
	return &gormLogger{log: log}
}

// custom logger for gorm
type gormLogger struct {
	log logging.Logger
}

// Format log
var sqlRegexp = regexp.MustCompile(`(\$\d+)|\?`)

// implement gorm logging interface
func (g *gormLogger) Print(v ...interface{}) {
	messages := []interface{}{}

	// taken from gorm log file
	if len(v) > 4 {
		messages = append(messages, fmt.Sprintf(" [%.2fms] ", float64(v[2].(time.Duration).Nanoseconds()/1e4)/100.0))
		messages = append(messages, fmt.Sprintf(sqlRegexp.ReplaceAllString(v[3].(string), "'%v'"), v[4].([]interface{})...))
	} else {
		for _, message := range v {
			messages = append(messages, fmt.Sprintf("%s", message))
		}
	}

	format := ""
	for i := 0; i < len(messages); i++ {
		format += "%s"
	}

	g.log.Debug(format, messages...)
}
