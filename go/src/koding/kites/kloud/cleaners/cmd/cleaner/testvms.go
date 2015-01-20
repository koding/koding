package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"time"
)

type TestVMS struct {
	Instances *lookup.MultiInstances

	testInstances *lookup.MultiInstances
}

func (t *TestVMS) Process() {
	t.testInstances = t.Instances.
		OlderThan(time.Hour*24).
		WithTag("koding-env", "sandbox", "dev").
		States("pending", "running", "stopping", "stopped")
}

func (t *TestVMS) Run() {
	if t.testInstances.Total() == 0 {
		return
	}

	t.testInstances.TerminateAll()
}

func (t *TestVMS) Result() string {
	return fmt.Sprintf("terminated '%d' instances tagged with [sandbox, dev]",
		t.testInstances.Total())
}

func (t *TestVMS) Info() *taskInfo {
	return &taskInfo{
		Title: "TestVMS",
		Desc:  "Terminate instances older than 24 hours andd tagged with [sandbox, dev]",
	}
}
