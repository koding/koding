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
	var result stopResult
	resp, err := KiteClient.Tell("stop", &stopArgs{MachineId: machineId})
	if err != nil {
		return err
	}

	if err := resp.Unmarshal(&result); err != nil {
		return err
	}

	return nil
}
