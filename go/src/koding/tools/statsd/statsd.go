package statsd

import (
	"fmt"
	client "github.com/etsy/statsd"
	"time"
)

// TODO: get from config
var (
	STATSD   = client.New("172.168.2.7", 8125)
	APP_NAME string
)

func SetAppName(name string) {
	APP_NAME = name
}

func Increment(name string) {
	STATSD.Increment(name)
}

func Decrement(name string) {
	STATSD.Decrement(name)
}

type StatdsTimer struct {
	StartTime, EndTime time.Time
	Name               string
}

func StartTimer(name string) *StatdsTimer {
	return &StatdsTimer{
		StartTime: time.Now(),
		Name:      name,
	}
}

func (s *StatdsTimer) Success() {
	s.End("success")
}

func (s *StatdsTimer) Failed() {
	s.End("failed")
}

func (s *StatdsTimer) End(status string) {
	s.EndTime = time.Now()
	duration := int64(s.EndTime.Sub(s.StartTime) / time.Millisecond)
	name := buildName(s.Name, status)

	STATSD.Timing(name, duration)
}

func buildName(eventName, status string) string {
	return fmt.Sprintf("koding.%v.%v.%v", APP_NAME, eventName, status)
}
