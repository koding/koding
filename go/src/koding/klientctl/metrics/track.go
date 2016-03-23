package metrics

func TrackInstall() error {
	mc := &Metric{
		Name: EventInstall,
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

	return sendMetric(mc)
}

func TrackUnmount(machine string) error {
	mc := &Metric{
		Name: EventUnmount,
		Properties: map[string]interface{}{
			"machine": machine,
		},
	}

	return sendMetric(mc)
}

func TrackSSH(machine string) error {
	mc := &Metric{
		Name: EventSSH,
		Properties: map[string]interface{}{
			"machine": machine,
		},
	}

	return sendMetric(mc)
}

func TrackSSHFailed(machine, errStr string) error {
	mc := &Metric{
		Name: EventSSHFailed,
		Properties: map[string]interface{}{
			"machine": machine,
			"error":   errStr,
		},
	}

	return sendMetric(mc)
}

func TrackRun(machine string) error {
	mc := &Metric{
		Name: EventRun,
		Properties: map[string]interface{}{
			"machine": machine,
		},
	}

	return sendMetric(mc)
}

func TrackRepair(machine string) error {
	mc := &Metric{
		Name: EventRepair,
		Properties: map[string]interface{}{
			"machine": machine,
		},
	}

	return sendMetric(mc)
}

func TrackRepairError(machine, errStr string) error {
	mc := &Metric{
		Name: EventRepairFailed,
		Properties: map[string]interface{}{
			"machine": machine,
			"error":   errStr,
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
