package repair

import (
	"fmt"
	"io/ioutil"
	"koding/klientctl/klient"
	"koding/klientctl/util"
	"koding/klientctl/util/testutil"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/koding/kite"

	. "github.com/smartystreets/goconvey/convey"
)

func TestKlientRunningRepairStatus(t *testing.T) {
	Convey("Given a running klient", t, func() {
		s := kite.New("server", "0.0.0")
		s.Config.DisableAuthentication = true
		ts := httptest.NewServer(s)
		klientAddress := fmt.Sprintf("%s/kite", ts.URL)

		r := &KlientRunningRepair{
			Stdout: util.NewFprint(ioutil.Discard),
			KlientService: &klient.KlientService{
				KlientAddress: klientAddress,
				PauseInterval: time.Millisecond,
				MaxAttempts:   5,
			},
			KlientOptions: klient.KlientOptions{
				Address: klientAddress,
				Name:    "client",
				Version: "0.0.0",
			},
		}

		Convey("It should show status ok", func() {
			ok, err := r.Status()
			So(ok, ShouldBeTrue)
			So(err, ShouldBeNil)
		})
	})

	Convey("Given klient running, but not dial-able", t, func() {
		// This web server responds like a kite, but can't be dialed
		ts := httptest.NewServer(http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, "Welcome to SockJS!\n")
			}))
		defer ts.Close()
		klientAddress := fmt.Sprintf("%s/kite", ts.URL)

		r := &KlientRunningRepair{
			Stdout: util.NewFprint(ioutil.Discard),
			KlientService: &klient.KlientService{
				KlientAddress: klientAddress,
				PauseInterval: time.Millisecond,
				MaxAttempts:   5,
			},
			KlientOptions: klient.KlientOptions{
				Address: klientAddress,
				Name:    "client",
				Version: "0.0.0",
			},
		}

		Convey("It should show status not ok", func() {
			ok, err := r.Status()
			So(ok, ShouldBeFalse)
			So(err, ShouldBeNil)
		})
	})

	Convey("Given a not running klient", t, func() {
		// 999 is just a randomly chosen port.
		klientAddress := "http://127.0.0.1:999/kite"
		r := &KlientRunningRepair{
			Stdout: util.NewFprint(ioutil.Discard),
			KlientService: &klient.KlientService{
				KlientAddress: klientAddress,
				PauseInterval: time.Millisecond,
				MaxAttempts:   5,
			},
			KlientOptions: klient.KlientOptions{
				Address: klientAddress,
				Name:    "client",
				Version: "0.0.0",
			},
		}

		Convey("It should show status not ok", func() {
			ok, err := r.Status()
			So(ok, ShouldBeFalse)
			So(err, ShouldBeNil)
		})
	})
}

func TestKlientRunningRepairRepair(t *testing.T) {
	Convey("", t, func() {
		fakeCommandRun := &testutil.FakeCommandRun{}
		// 999 is just a randomly chosen port.
		klientAddress := "http://127.0.0.1:999/kite"
		r := &KlientRunningRepair{
			Stdout: util.NewFprint(ioutil.Discard),
			KlientService: &klient.KlientService{
				KlientAddress: klientAddress,
				PauseInterval: time.Millisecond,
				MaxAttempts:   5,
			},
			KlientOptions: klient.KlientOptions{
				Address: klientAddress,
				Name:    "client",
				Version: "0.0.0",
			},
			Exec: fakeCommandRun,
		}

		Convey("It should call for klient to restart", func() {
			r.Repair()
			So(fakeCommandRun.RunLog, ShouldResemble, [][]string{
				[]string{"sudo", "kd", "restart"},
			})
		})

		Convey("It should fail if status still fails", func() {
			err := r.Repair()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "not-okay")
		})
	})
}
