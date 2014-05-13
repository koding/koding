package main

type DigitalOcean struct {
	ClientID string
	ApiKey   string
}

func (d *DigitalOcean) Build() error     { return nil }
func (d *DigitalOcean) Provision() error { return nil }
func (d *DigitalOcean) Start() error     { return nil }
func (d *DigitalOcean) Stop() error      { return nil }
func (d *DigitalOcean) Restart() error   { return nil }
func (d *DigitalOcean) Destroy() error   { return nil }
