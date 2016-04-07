package metrics

func TrackInstall(version int) error {
	mc := &Metric{
		Name: EventInstall,
		Properties: map[string]interface{}{
			"version": version,
		},
	}

	return sendMetric(mc)
}

func TrackMount(machine, mountPath string, opts map[string]interface{}) error {
	// don't track user owned info info like mountPath
	opts["machine"] = machine

	mc := &Metric{
		Name:       EventMount,
		Properties: opts,
	}
	c := NewDefaultClient()
	if err := c.SendMetric(mc); err != nil {
		return err
	}

	return nil
	//return c.TriggerMountStatusStart(machine)
}

func TrackUnmount(machine string, version int) error {
	mc := &Metric{
		Name: EventUnmount,
		Properties: map[string]interface{}{
			"machine": machine,
			"version": version,
		},
	}
	c := NewDefaultClient()
	if err := c.SendMetric(mc); err != nil {
		return err
	}

	//return c.TriggerMountStatusStop(machine)
	return nil
}

func TrackSSH(machine string, version int) error {
	mc := &Metric{
		Name: EventSSH,
		Properties: map[string]interface{}{
			"machine": machine,
			"version": version,
		},
	}

	return sendMetric(mc)
}

func TrackSSHFailed(machine, errStr string, version int) error {
	mc := &Metric{
		Name: EventSSHFailed,
		Properties: map[string]interface{}{
			"machine": machine,
			"error":   errStr,
			"version": version,
		},
	}

	return sendMetric(mc)
}

func TrackRun(machine string, version int) error {
	mc := &Metric{
		Name: EventRun,
		Properties: map[string]interface{}{
			"machine": machine,
			"version": version,
		},
	}

	return sendMetric(mc)
}

func TrackRepair(machine string, version int) error {
	mc := &Metric{
		Name: EventRepair,
		Properties: map[string]interface{}{
			"machine": machine,
			"version": version,
		},
	}

	return sendMetric(mc)
}

func TrackRepairError(machine, errStr string, version int) error {
	mc := &Metric{
		Name: EventRepairFailed,
		Properties: map[string]interface{}{
			"machine": machine,
			"error":   errStr,
			"version": version,
		},
	}

	return sendMetric(mc)
}

func TrackMountCheckSuccess(machine string) error {
	mc := &Metric{
		Name: EventMountCheckSuccess,
		Properties: map[string]interface{}{
			"machine": machine,
		},
	}

	return sendMetric(mc)
}

func TrackMountCheckFailure(machine, errStr string) error {
	mc := &Metric{
		Name: EventMountCheckFailed,
		Properties: map[string]interface{}{
			"machine": machine,
			"error":   errStr,
		},
	}

	return sendMetric(mc)
}

func sendMetric(mc *Metric) error {
	return NewDefaultClient().SendMetric(mc)
}
