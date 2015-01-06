package main

// request arguments
type stopArgs struct {
	MachineId string `json:"machineId"`
}

// response type
type stopResult struct {
	State   string `json:"state"`
	EventId string `json:"eventId"`
}

func stopVm(machineId string) error {
	_, err := controller.Klient.Tell("stop", &stopArgs{MachineId: machineId})
	return err
}
