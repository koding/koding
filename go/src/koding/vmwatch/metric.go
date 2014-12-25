package main

import (
	"koding/db/models"
	"time"
)

type Metric interface {
	GetAndSaveData(string) error
	GetMachinesOverLimit() ([]*models.Machine, error)
	IsUserOverLimit(string) LimitResponse
	GetName() string
}

type MetricData struct {
	Timestamp time.Time
	Value     float64
}

type LimitResponse struct {
	OverLimit                  bool
	CurrentUsage, AllowedUsage float64
}
