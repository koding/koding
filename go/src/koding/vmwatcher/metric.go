package main

import "koding/db/models"

type Metric interface {
	GetAndSaveData(string) error
	GetMachinesOverLimit(string) ([]*models.Machine, error)
	IsUserOverLimit(string, string) (*LimitResponse, error)
	GetName() string
	GetLimit(string) float64
	Save(string, float64) error
}
