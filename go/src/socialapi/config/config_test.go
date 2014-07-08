package config

import (
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

const (
	testConfigPath = "./test.toml"
)

func TestConfigMustRead(t *testing.T) {
	Convey("while testing MustRead", t, func() {
		Convey("valid testConfigPath should return config", func() {
			So(func() { MustRead(testConfigPath) }, ShouldNotPanic)
			So(MustRead(testConfigPath), ShouldNotBeNil)
		})
		Convey("invalid testConfigPath should panic", func() {
			So(func() { MustRead("testConfigPath") }, ShouldPanic)
		})
		Convey("setting socialapi env should override config", func() {
			env := "MehmetAli"
			err := os.Setenv("SOCIAL_API_ENV", env)
			So(err, ShouldBeNil)
			// just to be sure about the function will not panic
			So(func() { MustRead(testConfigPath) }, ShouldNotPanic)
			a := MustRead(testConfigPath)
			So(a.Environment, ShouldEqual, env)
		})
	})
}
