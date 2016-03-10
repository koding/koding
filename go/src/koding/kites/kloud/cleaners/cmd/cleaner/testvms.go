package main

import (
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/cleaners/lookup"
	"strings"
	"time"
)

type TestVMS struct {
	Instances *lookup.MultiInstances
	MongoDB   *mongodb.MongoDB

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
	t.testInstances.DeleteDocs(t.MongoDB)
}

func (t *TestVMS) Result() string {
	if t.testInstances.Total() == 0 {
		return ""
	}

	return fmt.Sprintf("terminated '%d' instances. instances: %s",
		t.testInstances.Total(), strings.Join(t.testInstances.Ids(), ","))
}

func (t *TestVMS) Info() *taskInfo {
	return &taskInfo{
		Title: "TestVMS",
		Desc:  "Terminate instances older than 24 hours andd tagged with [sandbox, dev]",
	}
}
