package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestEnvData(t *testing.T) {
	Convey("When user has machines", t, func() {
		Convey("Then it should return machines", t, func() {
		})

		Convey("When user has workspaces", t, func() {
			Convey("Then it should return workspaces", t, func() {
			})
		})
	})

	Convey("When user has shared machines", t, func() {
		Convey("Then it should return machines", t, func() {
		})

		Convey("When user has shared workspaces", t, func() {
			Convey("Then it should return workspaces", t, func() {
			})
		})
	})
}
