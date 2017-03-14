package tests

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/mux"
	"strconv"
	"testing"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
	stripe "github.com/stripe/stripe-go"
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

	if r.Conf.Debug {
		stripe.LogLevel = 3
	}

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

// WithTestServer creates a test server
func WithTestServer(t *testing.T, handlerAdder func(m *mux.Mux), f func(url string)) {
	WithRunner(t, func(r *runner.Runner) {
		port := GetFreePort()
		mc := mux.NewConfig("test", "localhost", port)
		mc.Debug = r.Conf.Debug
		m := mux.New(mc, r.Log, r.Metrics)

		handlerAdder(m)

		m.Listen()

		go r.Listen()

		f(fmt.Sprintf("http://localhost:%s", port))

		if err := r.Close(); err != nil {
			t.Fatalf("server close errored: %s", err.Error())
		}

		// shutdown server
		m.Close()
	})
}

// WithStubData creates bare-bones for operating against koding services.
func WithStubData(endpoint string, f func(username string, groupName string, sessionID string)) {
	acc, _, groupName := models.CreateRandomGroupDataWithChecks()

	group, err := modelhelper.GetGroup(groupName)
	ResultedWithNoErrorCheck(group, err)

	err = modelhelper.MakeAdmin(bson.ObjectIdHex(acc.OldId), group.Id)
	So(err, ShouldBeNil)

	ses, err := modelhelper.FetchOrCreateSession(acc.Nick, groupName)
	ResultedWithNoErrorCheck(ses, err)

	f(acc.Nick, groupName, ses.ClientId)
}
