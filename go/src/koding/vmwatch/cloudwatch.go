package main

import "time"

type Cloudwatch struct {
	Name string
}

func (c *Cloudwatch) GetAndSaveData(username string, t time.Time) error {
	return nil
}

func (c *Cloudwatch) GetVmsOverLimit(t time.Time) []string {
	return []string{}
}

func (c *Cloudwatch) IsUserOverLimit(username string, t time.Time) LimitResponse {
	return LimitResponse{}
}
