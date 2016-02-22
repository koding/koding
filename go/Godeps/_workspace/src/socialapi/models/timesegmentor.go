package models

import (
	"strconv"
	"time"
)

type TimeSegmentor struct {
	interval int
}

func NewTimeSegmentor(interval int) *TimeSegmentor {
	return &TimeSegmentor{interval}
}

func (t *TimeSegmentor) GetCurrentSegment() string {
	segment := time.Now().Minute() / t.interval

	return strconv.Itoa(segment)
}

func (t *TimeSegmentor) GetNextSegment() string {
	// divide time range into segments (for 30m range segment can be 0 or 1)
	segment := time.Now().Minute() / t.interval
	segment = (segment + 1) % (60 / t.interval)

	return strconv.Itoa(segment)
}
