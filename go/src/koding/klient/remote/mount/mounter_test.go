package mount

import (
	"syscall"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRetryOnErr(t *testing.T) {
	Convey("Given a function that returns an error", t, func() {
		retryCount := 0
		retry := func() error {
			retryCount++
			return syscall.ECONNREFUSED
		}
		retryUntil3 := func() error {
			retryCount++
			if retryCount >= 3 {
				return nil
			}
			return syscall.ECONNREFUSED
		}
		blacklist := []error{syscall.ECONNABORTED}

		Convey("It should retry the specified number of times", func() {
			retryOnErr(3, 1, blacklist, nil, retry)
			So(retryCount, ShouldEqual, 3)
		})

		Convey("It should return the error after max attempts", func() {
			err := retryOnErr(3, 1, blacklist, nil, retry)
			So(err, ShouldEqual, syscall.ECONNREFUSED)
		})

		Convey("It should stop once the func succeeds", func() {
			retryOnErr(4, 1, blacklist, nil, retryUntil3)
			So(retryCount, ShouldEqual, 3)
		})

		Convey("It should not return an error if the func eventually succeeds", func() {
			err := retryOnErr(4, 1, blacklist, nil, retryUntil3)
			So(err, ShouldBeNil)
		})
	})

	Convey("Given a function that does not return a blacklisted error", t, func() {
		retryCount := 0
		retry := func() error {
			retryCount++
			return nil
		}

		Convey("It should try once", func() {
			retryOnErr(3, 1, nil, nil, retry)
			So(retryCount, ShouldEqual, 1)
		})

		Convey("It should not return an error", func() {
			So(retryOnErr(3, 1, nil, nil, retry), ShouldBeNil)
		})
	})

	Convey("Given a function that returns a blacklisted error", t, func() {
		retryCount := 0
		retry := func() error {
			retryCount++
			return syscall.ECONNREFUSED
		}
		blacklist := []error{syscall.ECONNREFUSED}

		Convey("It should return an error immediately if it has been blacklisted", func() {
			err := retryOnErr(4, 1, blacklist, nil, retry)
			So(err, ShouldEqual, syscall.ECONNREFUSED)
			So(retryCount, ShouldEqual, 1)
		})
	})
}
