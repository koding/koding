package tests

import (
	"koding/db/mongodb/modelhelper"
	"net"
	"socialapi/config"
	"strconv"
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

// GetFreePort find a free port on the current system.
func GetFreePort() string {
	addr, err := net.ResolveTCPAddr("tcp", "localhost:0")
	if err != nil {
		panic(err)
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		panic(err)
	}
	defer l.Close()

	return strconv.Itoa(l.Addr().(*net.TCPAddr).Port)
}
