package team

import (
	"socialapi/config"

	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTeam(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	Convey("given a controller", t, func() {
		NewController(r.Log, appConfig)
		Convey("when we add a new participant into a channel", func() {
			Convey("participant should be added to default channels", func() {

			})
		})
	})
}
