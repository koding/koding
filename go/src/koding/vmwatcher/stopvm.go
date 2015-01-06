package main

// request arguments
type stopArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
}

// response type
type stopResult struct {
	State   string `json:"state"`
	EventId string `json:"eventId"`
}

func stopVm(machineId, reason string) error {
	_, err := controller.Klient.Tell("stop", &stopArgs{
		MachineId: machineId, Reason: reason,
	})

	return err
}
