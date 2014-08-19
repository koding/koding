package config

import (
	"os"
	"strconv"
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
		Convey("getting string env variable should override config", func() {
			conf := MustRead(testConfigPath)
			os.Setenv("RABBITMQ_HOST", hostname)
			getStringEnvVar(&conf.Mq.Host, "RABBITMQ_HOST")
			So(conf.Mq.Host, ShouldEqual, hostname)

		})
		Convey("getting int env variable should override config", func() {
			conf := MustRead(testConfigPath)
			os.Setenv("RABBITMQ_PORT", strconv.Itoa(port))
			getIntEnvVar(&conf.Mq.Port, "RABBITMQ_PORT")
			So(conf.Mq.Port, ShouldEqual, port)

			os.Setenv("RABBITMQ_PORT", "eighty")
			So(func() { getIntEnvVar(&conf.Mq.Port, "RABBITMQ_PORT") }, ShouldPanic)

			os.Setenv("RABBITMQ_PORT", "")
		})
		Convey("setting socialapi env should override config", func() {
			err := os.Setenv("SOCIAL_API_ENV", env)
			So(err, ShouldBeNil)
			// just to be sure about the function will not panic
			So(func() { MustRead(testConfigPath) }, ShouldNotPanic)
			a := MustRead(testConfigPath)
			So(a.Environment, ShouldEqual, env)
		})
		Convey("setting socialapi hostname should override config", func() {
			err := os.Setenv("SOCIAL_API_HOSTNAME", hostname)
			So(err, ShouldBeNil)
			aPath := MustRead(testConfigPath)
			So(aPath.Hostname, ShouldEqual, hostname)
		})
	})
}
