package config

import (
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

const (
	testConfigPath = "./test.toml"
	env            = "MehmetAli"
	hostname       = "Koding"
	port           = 5672
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
			err := os.Setenv("KONFIG_SOCIALAPI_ENVIRONMENT", env)
			So(err, ShouldBeNil)
			// just to be sure about the function will not panic
			So(func() { MustRead(testConfigPath) }, ShouldNotPanic)
			a := MustRead(testConfigPath)
			So(a.Environment, ShouldEqual, env)
		})
		Convey("setting socialapi hostname should override config", func() {
			err := os.Setenv("KONFIG_SOCIALAPI_HOSTNAME", hostname)
			So(err, ShouldBeNil)
			aPath := MustRead(testConfigPath)
			So(aPath.Hostname, ShouldEqual, hostname)
		})
	})
}
