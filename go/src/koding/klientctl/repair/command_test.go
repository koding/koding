package repair

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"koding/klient/remote/req"
	"koding/klientctl/list"
	"koding/klientctl/util/testutil"
	"testing"

	"github.com/koding/logging"
	. "github.com/smartystreets/goconvey/convey"
)

type fakeRepairKlient struct {
	ReturnInfos list.KiteInfos
}

func (k *fakeRepairKlient) RemoteStatus(req.Status) error {
	return nil
}

func (k *fakeRepairKlient) RemoteList() (list.KiteInfos, error) {
	return k.ReturnInfos, nil
}

var discardLogger logging.Logger

func init() {
	discardLogger = logging.NewLogger("test")
	discardLogger.SetHandler(logging.NewWriterHandler(ioutil.Discard))
}

func TestRepairCommandRun(t *testing.T) {
	Convey("It should require MountName", t, func() {
		var stdout bytes.Buffer
		c := &Command{
			Log:    discardLogger,
			Stdout: &stdout,
			Helper: func(w io.Writer) { fmt.Fprintln(w, "help called") },
		}

		exit, err := c.Run()
		So(err, ShouldNotBeNil)
		So(exit, ShouldNotEqual, 0)
		So(err.Error(), ShouldContainSubstring, "mountname")

		Convey("It should print help", func() {
			So(stdout.String(), ShouldContainSubstring, "required")
			So(stdout.String(), ShouldContainSubstring, "help called")
		})
	})

	Convey("Given repairer statuses that pass right away", t, func() {
		repairerA := &fakeRepairer{}
		repairerB := &fakeRepairer{}

		var stdout bytes.Buffer
		c := &Command{
			Options: Options{
				MountName: "foo",
			},
			Log:            discardLogger,
			Stdout:         &stdout,
			Helper:         func(w io.Writer) { fmt.Fprintln(w, "help called") },
			SetupRepairers: []Repairer{},
			Repairers:      []Repairer{repairerA, repairerB},
			KlientService:  &testutil.FakeService{},
			Klient: &fakeRepairKlient{
				ReturnInfos: []list.KiteInfo{list.KiteInfo{VMName: "foo"}},
			},
		}

		Convey("It should call all of the repairers status, but not Repair", func() {
			exit, err := c.Run()
			So(err, ShouldBeNil)
			So(exit, ShouldEqual, 0)
			So(repairerA.StatusCount, ShouldEqual, 1)
			So(repairerA.RepairCount, ShouldEqual, 0)
			So(repairerB.StatusCount, ShouldEqual, 1)
			So(repairerB.RepairCount, ShouldEqual, 0)
		})
	})

	Convey("Given repairers that fail", t, func() {
		repairerA := &fakeRepairer{}
		repairerB := &fakeRepairer{StatusFailUntil: 2, RepairFailUntil: 2}
		repairerC := &fakeRepairer{}

		var stdout bytes.Buffer
		c := &Command{
			Options: Options{
				MountName: "foo",
			},
			Log:            discardLogger,
			Stdout:         &stdout,
			Helper:         func(w io.Writer) { fmt.Fprintln(w, "help called") },
			SetupRepairers: []Repairer{},
			Repairers:      []Repairer{repairerA, repairerB, repairerC},
			KlientService:  &testutil.FakeService{},
			Klient: &fakeRepairKlient{
				ReturnInfos: []list.KiteInfo{list.KiteInfo{VMName: "foo"}},
			},
		}

		Convey("It should call all of the repairers status, and repair the status that fails", func() {

			exit, err := c.Run()
			So(err, ShouldNotBeNil)
			// Our error should be the one from fakeRepairer, not anything else
			So(err.Error(), ShouldContainSubstring, "fail for request")
			So(exit, ShouldNotEqual, 0)
			So(repairerA.StatusCount, ShouldEqual, 1)
			So(repairerA.RepairCount, ShouldEqual, 0)
			So(repairerB.StatusCount, ShouldEqual, 1)
			// Repair will be called once, and fail - causing Run() to fail.
			So(repairerB.RepairCount, ShouldEqual, 1)
			So(repairerC.StatusCount, ShouldEqual, 0)
			So(repairerC.RepairCount, ShouldEqual, 0)
		})
	})
}
