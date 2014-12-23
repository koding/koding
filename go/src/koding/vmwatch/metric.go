package main

import "time"

type Metric interface {
	GetAndSaveData(string, time.Time) error
	GetVmsOverLimit(time.Time) []string
	IsVmOverLimit(string, time.Time) LimitResponse
}

type MetricData struct {
	Timestamp time.Time
	Value     float64
}

type LimitResponse struct {
	OverLimit                  bool
	CurrentUsage, AllowedUsage float64
}
