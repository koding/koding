package api

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
