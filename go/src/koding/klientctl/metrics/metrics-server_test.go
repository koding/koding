package metrics

import (
	"fmt"
	"io/ioutil"
	"os"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestServer(t *testing.T) {
	Convey("Given a not running server", t, func() {
		t, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)

		s := NewDefaultServer(t)

		Convey("Pid", func() {
			Convey("It should return err when trying to find pid", func() {
				_, err := s.Pid()
				So(err, ShouldEqual, ErrNoPid)
			})
		})

		Convey("IsRunning", func() {
			Convey("It should return false", func() {
				So(s.IsRunning(), ShouldBeFalse)
			})
		})
	})

	Convey("Given a running server", t, func() {
		t, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)

		s := NewDefaultServer(t)

		go s.Start(os.Getpid())

		Convey("Pid", func() {
			Convey("It should return pid of process", func() {
				time.Sleep(1 * time.Second)

				pid, err := s.Pid()
				So(err, ShouldBeNil)
				So(pid, ShouldEqual, fmt.Sprintf("%d", os.Getpid()))
			})
		})

		Convey("IsRunning", func() {
			Convey("It should return true", func() {
				So(s.IsRunning(), ShouldBeTrue)
			})
		})

		Convey("It should accept command to start filesystem test", func() {
		})
	})
}
