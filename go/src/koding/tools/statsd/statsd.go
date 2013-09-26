// A tiny wrapper around the offical etsy statd package.
//
// Example:
//    statsd.SetAppName("myWorker")
//
//    // from inside a function
//    sTimer := statsd.StartTimer("sendRequest")
//    err := doWork()
//    if err != nil {
//      s.Timer.Failed()
//      return err
//    }
//
//    sTimer.Success()
package statsd

import (
	"fmt"
	client "github.com/etsy/statsd"
	"koding/tools/config"
	"time"
)

var (
	STATSD   = client.New(config.Current.Statsd.Ip, config.Current.Statsd.Port)
	APP_NAME string
)

// App name is used as a namespace, usually set to the name of
// the worker that uses this package.
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

// Sends duration it took for event to complete.
//
// Events name follow the pattern:
//    koding.<app name>.<event name>.<status>
// Ex:
//    koding.myWorker.work.success
//    koding.myWorker.work.failure
//
// Success() and Failure() are helper methods that adds respective
// status to event name automatically.
func (s *StatdsTimer) End(status string) {
	s.EndTime = time.Now()
	duration := int64(s.EndTime.Sub(s.StartTime) / time.Millisecond)
	name := buildName(s.Name, status)

	STATSD.Timing(name, duration)
}

func buildName(eventName, status string) string {
	return fmt.Sprintf("koding.%v.%v.%v", APP_NAME, eventName, status)
}
