package api

type Droplet struct {
	Id               int      `json:"id" mapstructure:"id"`
	Name             string   `json:"name" mapstructure:"name"`
	ImageId          int      `json:"image_id" mapstructure:"image_id"`
	SizeId           int      `json:"size_id" mapstructure:"size_id"`
	RegionId         int      `json:"region_id" mapstructure:"region_id"`
	EventId          int      `json:"event_id" mapstructure:"event_id"`
	BackupsActive    bool     `json:"backups_active" mapstructure:"backups_active"`
	Backups          []string `json:"backups" mapstructure:"backups"`
	Snapshots        []string `json:"snapshots" mapstructure:"snapshots"`
	IpAddress        string   `json:"ip_address" mapstructure:"ip_address"`
	PrivateIpAddress string   `json:"private_ip_address" mapstructure:"private_ip_address"`
	Locked           bool     `json:"locked" mapstructure:"locked"`
	Status           string   `json:"status" mapstructure:"status"`
	CreatedAt        string   `json:"created_at" mapstructure:"created_at"`
}

type Droplets []Droplet

func (d Droplets) Filter(name string) Droplets {
	return d
}
