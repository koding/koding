package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"testing"
)

func TestFrontpageListingOperations(t *testing.T) {

	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	testFrontpageOperations()
}
