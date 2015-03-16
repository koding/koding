package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"testing"

	"github.com/koding/runner"
)

func TestFrontpageListingOperations(t *testing.T) {

	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	testFrontpageOperations()
}
