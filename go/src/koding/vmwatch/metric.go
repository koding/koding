package main

import "koding/db/models"

type Metric interface {
	GetAndSaveData(string) error
	GetMachinesOverLimit() ([]*models.Machine, error)
	IsUserOverLimit(string) (*LimitResponse, error)
	GetName() string
}
