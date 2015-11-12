package main

import (
	"errors"
	"testing"

	"github.com/koding/klientctl/util"
	. "github.com/smartystreets/goconvey/convey"
)

func TestAdminRequired(t *testing.T) {
	Convey("Given the user has permissions", t, func() {
		p := &util.Permissions{
			AdminChecker: func() (bool, error) { return true, nil },
		}

		Convey("When the user gave no args", func() {
			Convey("Then don't return an error", func() {
				args := []string{"kd"}
				reqs := []string{"start", "stop"}
				So(AdminRequired(args, reqs, p), ShouldBeNil)
			})
		})

		Convey("When the command is required", func() {
			Convey("Then don't return an error", func() {
				args := []string{"kd", "stop"}
				reqs := []string{"start", "stop"}
				So(AdminRequired(args, reqs, p), ShouldBeNil)
			})
		})

		Convey("When the command is not required", func() {
			Convey("Then don't return an error", func() {
				args := []string{"kd", "list"}
				reqs := []string{"start", "stop"}
				So(AdminRequired(args, reqs, p), ShouldBeNil)
			})
		})
	})

	Convey("Given the user does not have permission", t, func() {
		p := &util.Permissions{
			AdminChecker: func() (bool, error) { return false, nil },
		}

		Convey("When the bin has no args", func() {
			Convey("Then don't return an error", func() {
				args := []string{"kd"}
				reqs := []string{"start", "stop"}
				So(AdminRequired(args, reqs, p), ShouldBeNil)
			})
		})

		Convey("When the command is required", func() {
			Convey("Then return an error", func() {
				args := []string{"kd", "stop"}
				reqs := []string{"start", "stop"}
				So(AdminRequired(args, reqs, p), ShouldNotBeNil)
			})
		})

		Convey("When the command is not required", func() {
			Convey("Then don't return an error", func() {
				args := []string{"kd", "list"}
				reqs := []string{"start", "stop"}
				So(AdminRequired(args, reqs, p), ShouldBeNil)
			})
		})
	})

	Convey("Given the admin checker errors", t, func() {
		p := &util.Permissions{
			AdminChecker: func() (bool, error) {
				return false, errors.New("Fake error")
			},
		}

		Convey("Then allow the user to run the command", func() {
			args := []string{"kd", "stop"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})
	})
}
