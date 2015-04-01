package kloud

func (k *Kloud) track(provider, id, call string) {
	if k.Metrics == nil {
		return
	}

	tags := []string{"action:" + call}

	if id != "" {
		tags = append(tags, "instanceId:"+id)
	}

	if provider != "" {
		tags = append(tags, "provider:"+provider)
	}

	k.Metrics.Count(
		"call_to_describe_instance.counter", // metric name
		1,    // count
		tags, // tags for metric call
		1.0,  // rate
	)
}
