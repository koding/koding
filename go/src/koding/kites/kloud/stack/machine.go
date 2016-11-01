package stack

import "github.com/koding/kite"

type MachineListRequest struct {
	Provider string `json:"provider,omitempty"`
	Team     string `json:"team,omitempty"`
}

type MachineItem struct {
	Team         string `json:"team"`
	Provider     string `json:"provider"`
	ID           string `json:"id"`
	Label        string `json:"label"`
	Status       string `json:"status"`
	StatusReason string `json:"statusReason"`
}

type MachineListResponse struct {
	Machines []MachineItem `json:"machines"`
}

func (k *Kloud) MachineList(r *kite.Request) (interface{}, error) {
	return nil, nil
}
