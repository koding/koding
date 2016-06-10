package config

import (
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

const (
	testConfigPath = "./dev.toml"
	protocol       = "MehmetAli"
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
		Convey("setting socialapi protocol should override config", func() {
			err := os.Setenv("KONFIG_SOCIALAPI_PROTOCOL", protocol)
			So(err, ShouldBeNil)
			// just to be sure about the function will not panic
			So(func() { MustRead(testConfigPath) }, ShouldNotPanic)
			a := MustRead(testConfigPath)
			So(a.Protocol, ShouldEqual, protocol)
		})
	})
}
