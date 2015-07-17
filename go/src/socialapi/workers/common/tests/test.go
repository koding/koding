package tests

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func ResultedWithNoErrorCheck(result interface{}, err error) {
	So(err, ShouldBeNil)
	So(result, ShouldNotBeNil)
}

func WithRunner(t *testing.T, f func(*runner.Runner)) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	f(r)
}
