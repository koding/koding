package main

import (
	"errors"
	"testing"

	"github.com/koding/klient/cmd/klientctl/util"
	. "github.com/smartystreets/goconvey/convey"
)

func TestAdminRequired(t *testing.T) {
	Convey("If the user has permissions, it", t, func() {
		p := &util.Permissions{
			AdminChecker: func() (bool, error) { return true, nil },
		}

		Convey("Should not return an error with no bin args", func() {
			args := []string{"kd"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})

		Convey("Should not return an error for a required command", func() {
			args := []string{"kd", "stop"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})

		Convey("Should not return an error for a not required command", func() {
			args := []string{"kd", "list"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})
	})

	Convey("If the user does not have permissions, it", t, func() {
		p := &util.Permissions{
			AdminChecker: func() (bool, error) { return false, nil },
		}

		Convey("Should not return an error with no bin args", func() {
			args := []string{"kd"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})

		Convey("Should return an error for a required command", func() {
			args := []string{"kd", "stop"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldNotBeNil)
		})

		Convey("Should not return an error for a not required command", func() {
			args := []string{"kd", "list"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})
	})

	Convey("If the admin checker errors", t, func() {
		p := &util.Permissions{
			AdminChecker: func() (bool, error) {
				return false, errors.New("Fake error")
			},
		}

		Convey("Allow the user to run the command", func() {
			args := []string{"kd", "stop"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})
	})
}
