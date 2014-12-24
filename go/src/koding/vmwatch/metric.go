package main

import "time"

type Metric interface {
	GetAndSaveData(string) error
	GetVmsOverLimit() []string
	IsUserOverLimit(string) LimitResponse
}

type MetricData struct {
	Timestamp time.Time
	Value     float64
}

type LimitResponse struct {
	OverLimit                  bool
	CurrentUsage, AllowedUsage float64
}
