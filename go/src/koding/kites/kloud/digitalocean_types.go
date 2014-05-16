package main

type Event struct {
	Status string `json:"status" mapstructure:"status"`
	Event  struct {
		Id           int    `json:"id" mapstructure:"id"`
		ActionStatus string `json:"action_status" mapstructure:"action_status"`
		DropletID    int    `json:"droplet_id" mapstructure:"droplet_id"`
		EventTypeID  int    `json:"event_type_id" mapstructure:"event_type_id"`
		Percentage   string `json:"percentage" mapstructure:"percentage"`
	} `json:"event" mapstructure:"event"`
}

type DropletInfo struct {
	Status  string `json:"status" mapstructure:"status"`
	Droplet struct {
		Id       int    `json:"id" mapstructure:"id"`
		Hostname string `json:"hostname" mapstructure:"hostname"`
		ImageId  int    `json:"image_id" mapstructure:"image_id"`
		SizeId   int    `json:"size_id" mapstructure:"size_id"`
		EventId  int    `json:"event_id" mapstructure:"event_id"`
	} `json:"droplet" mapstructure:"droplet"`
}

type DropletsResp struct {
	Droplets []Droplet `json:"droplets"`
}

type Droplet struct {
	Id               int    `json:"id" mapstructure:"id"`
	Name             string `json:"name" mapstructure:"name"`
	ImageId          int    `json:"image_id" mapstructure:"image_id"`
	SizeId           int    `json:"size_id" mapstructure:"size_id"`
	RegionId         int    `json:"region_id" mapstructure:"region_id"`
	EventId          int    `json:"event_id" mapstructure:"event_id"`
	BackupsActive    bool   `json:"backups_active" mapstructure:""`
	IpAddress        string `json:"ip_address" mapstructure:"ip_address"`
	PrivateIpAddress string `json:"private_ip_address" mapstructure:"private_ip_address"`
	Locked           bool   `json:"locked" mapstructure:"locked"`
	Status           string `json:"status" mapstructure:"status"`
	CreatedAt        string `json:"created_at" mapstructure:"created_at"`
}
