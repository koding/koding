package tracer

import (
	"fmt"
)

type Message struct {
	Message     string  `json:"message"`
	CurrentStep int     `json:"currentStep"`
	TotalStep   int     `json:"totalStep"`
	Err         error   `json:"error"`
	ElapsedTime float64 `json:"elapsedTime"` // time.Duration.Seconds()
}

type Tracer interface {
	Trace(Message)
}

type FmtTracer struct {
	discard bool
}

func DefaultTracer() Tracer {
	return &FmtTracer{}
}

func DiscardTracer() Tracer {
	return &FmtTracer{discard: true}
}

func (f *FmtTracer) Trace(msg Message) {
	if f.discard {
		return // don't do anything for discard, it's a no-op
	}

	fmt.Println(msg.String())
}

func (m *Message) String() string {
	if m.Err != nil {
		return fmt.Sprintf("msg: %s. elapsedTime: %f. err: %s.",
			m.Message, m.ElapsedTime, m.Err)
	}

	return fmt.Sprintf("msg: %s. elapsedTime: %f", m.Message, m.ElapsedTime)
}
