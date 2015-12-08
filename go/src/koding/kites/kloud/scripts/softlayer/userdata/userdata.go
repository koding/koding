package userdata

type Value struct {
	Username        string
	Hostname        string
	Groups          []string
	SSHKeys         []string
	KiteKey         string
	LatestKlientURL string // URL of the latest version of the Klient package
}
