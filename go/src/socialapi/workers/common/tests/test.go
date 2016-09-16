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

func WithConfiguration(t *testing.T, f func(c *config.Config)) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatal(err.Error())
	}
	defer r.Close()

	c := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(c.Mongo)
	defer modelhelper.Close()

	f(c)
}
