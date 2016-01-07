package main

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	magicInstanceId = "i-ad086943"
	testUsername    = "test"
	usEastRegion    = "us-east-1"
)

func init() {
	initialize()
}

func TestRunningMachine(t *testing.T) {
	Convey("Given running machine", t, func() {
		machine, err := insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return the machine", func() {
			machines, err := getRunningVms()
			So(err, ShouldBeNil)

			So(len(machines), ShouldEqual, 1)
		})

		Reset(func() {
			removeUserMachine(machine.Credential)
		})
	})
}

func TestOverlimitMachines(t *testing.T) {
	Convey("Given queued machine", t, func() {
		machine, err := insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should queue & pop the machine", func() {
			err := queueUsernamesForMetricGet()
			So(err, ShouldBeNil)

			queuedMachines, err := popMachinesForMetricGet(NetworkOut)
			So(err, ShouldBeNil)
			So(len(queuedMachines), ShouldEqual, 1)

			So(queuedMachines[0].Credential, ShouldEqual, machine.Credential)
		})

		Reset(func() {
			removeUserMachine(machine.Credential)
		})
	})
}

func TestStoppingMachines(t *testing.T) {
	Convey("Given running machines that is over limit", t, func() {
		machine, err := insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return machine", func() {
			networkOutMetric := metricsToSave[0]
			err := storage.SaveScore(networkOutMetric.GetName(), machine.Credential, NetworkOutLimit*3)
			So(err, ShouldBeNil)

			for _, metric := range metricsToSave {
				machines, err := metric.GetMachinesOverLimit(StopLimitKey)
				So(err, ShouldBeNil)

				So(len(machines), ShouldEqual, 1)
			}
		})

		Reset(func() {
			removeUserMachine(machine.Credential)
		})
	})
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func insertRunningMachine() (*models.Machine, error) {
	user, err := modeltesthelper.CreateUserWithMachine("indianajones")
	if err != nil {
		return nil, err
	}

	machines, err := modelhelper.GetMachinesByUsername(user.Name)
	if err != nil {
		return nil, err
	}

	if len(machines) == 0 {
		return nil, errors.New("no machines")
	}

	for _, machine := range machines {
		err := modelhelper.ChangeMachineState(machine.ObjectId, modelhelper.MachineStateRunning)
		if err != nil {
			return nil, err
		}
	}

	return machines[0], nil
}

func removeUserMachine(username string) {
	modelhelper.RemoveUser(username)

	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"credential": username})
	}

	modelhelper.Mongo.Run(modelhelper.MachinesColl, query)
}

func buildPaymentServer(planTitle string) (string, *httptest.Server) {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, fmt.Sprintf(`{"planTitle":"%s"}`, planTitle))
	})

	server := httptest.NewServer(mux)
	url, _ := url.Parse(server.URL)

	return url.String(), server
}
