package main

import (
	"errors"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

type fakeAdminChecker struct {
	ReturnIsAdmin bool
	ReturnError   error
}

func (c *fakeAdminChecker) IsAdmin() (bool, error) {
	return c.ReturnIsAdmin, c.ReturnError
}

func TestAdminRequired(t *testing.T) {
	Convey("Given the user has permissions", t, func() {
		p := &fakeAdminChecker{ReturnIsAdmin: true}

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
		p := &fakeAdminChecker{ReturnIsAdmin: false}

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
		p := &fakeAdminChecker{ReturnError: errors.New("Fake error")}

		Convey("Then allow the user to run the command", func() {
			args := []string{"kd", "stop"}
			reqs := []string{"start", "stop"}
			So(AdminRequired(args, reqs, p), ShouldBeNil)
		})
	})
}
