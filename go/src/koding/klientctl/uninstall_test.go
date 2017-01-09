package main

import (
	"errors"
	"testing"

	"github.com/koding/logging"
	. "github.com/smartystreets/goconvey/convey"
)

func testableRemover(s *[]string) func(string) error {
	return func(p string) error {
		*s = append(*s, p)
		return nil
	}
}

type testableService struct {
	Uninstalled bool
}

func (u *testableService) Uninstall() error {
	u.Uninstalled = true
	return nil
}

func (u *testableService) Stop() error {
	return nil
}

var testLog = logging.NewCustom("test-uninstall", true)

func TestRemoveKlientFiles(t *testing.T) {
	Convey("Given the KlientDirectory is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				KlientFilename:        "baz",
				KlientshFilename:      "baz.sh",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientFiles(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given the KlientParentDirectory is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientDirectory:  "foo",
				KlientFilename:   "baz",
				KlientshFilename: "baz.sh",
				remover:          testableRemover(&removed),
				log:              testLog,
			}
			So(u.RemoveKlientFiles(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given the KlientFilename is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				KlientDirectory:       "bar",
				KlientshFilename:      "baz.sh",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientFiles(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given the KlientshFilename is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				KlientDirectory:       "bar",
				KlientFilename:        "baz",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientFiles(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given that everything is configured properly", t, func() {
		Convey("Then remove the klient files", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				KlientDirectory:       "bar",
				KlientFilename:        "baz",
				KlientshFilename:      "baz.sh",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientFiles(), ShouldBeNil)
			So(removed, ShouldResemble, []string{
				"foo/bar/baz",
				"foo/bar/baz.sh",
			})
		})
	})
}

func TestRemoveKlientDirectories(t *testing.T) {
	Convey("Given the KlientDirectory is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientDirectories(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given the KlientParentDirectory is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientDirectory: "foo",
				remover:         testableRemover(&removed),
				log:             testLog,
			}
			So(u.RemoveKlientDirectories(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given the KlientDirectory is absolute", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				KlientDirectory:       "/bar",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientDirectories(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given everything is configured properly", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				KlientParentDirectory: "foo",
				KlientDirectory:       "bar/baz",
				remover:               testableRemover(&removed),
				log:                   testLog,
			}
			So(u.RemoveKlientDirectories(), ShouldBeNil)
			So(removed, ShouldResemble, []string{
				"foo/bar/baz",
				"foo/bar",
			})
		})

		Convey("And a directory cannot be removed", func() {
			Convey("Then return an error", func() {
				var removed []string
				u := &Uninstall{
					KlientParentDirectory: "foo",
					KlientDirectory:       "bar/baz/boop",
					remover: func(p string) error {
						// error on foo/bar to simulate a failure
						if p == "foo/bar" {
							return errors.New("Testing failure, cannot remove foo/bar")
						}
						removed = append(removed, p)
						return nil
					},
					log: testLog,
				}
				So(u.RemoveKlientDirectories(), ShouldNotBeNil)
				So(removed, ShouldResemble, []string{
					"foo/bar/baz/boop",
					"foo/bar/baz",
				})
			})
		})
	})
}

func TestRemoveKlientctl(t *testing.T) {
	Convey("Given the KlientctlPath is empty", t, func() {
		Convey("Then return an error", func() {
			var removed []string
			u := &Uninstall{
				remover: testableRemover(&removed),
				log:     testLog,
			}
			So(u.RemoveKlientctl(), ShouldNotBeNil)
			So(removed, ShouldBeNil)
		})
	})

	Convey("Given that the KlientctlPath is not empty", t, func() {
		Convey("Then remove the give path", func() {
			var removed []string
			u := &Uninstall{
				KlientctlPath: "foo",
				remover:       testableRemover(&removed),
				log:           testLog,
			}
			So(u.RemoveKlientctl(), ShouldBeNil)
			So(removed, ShouldResemble, []string{
				"foo",
			})
		})
	})
}

func TestUninstall(t *testing.T) {
	Convey("Given the it is configured properly", t, func() {
		var (
			removed []string
			service = &testableService{}
		)
		u := &Uninstall{
			ServiceUninstaller:    service,
			KlientctlPath:         "/usr/local/bin/kd",
			KlientParentDirectory: "/opt",
			KlientDirectory:       "kite/klient",
			KlientFilename:        "klient",
			KlientshFilename:      "klient.sh",
			remover:               testableRemover(&removed),
			log:                   testLog,
		}

		Convey("Then remove the expected files", func() {
			u.Uninstall()
			So(service.Uninstalled, ShouldBeTrue)

			// This is a bit brittle due to execution order, but most of the order
			// is important since files need to go before dirs, and etc. Therefor
			// some brittleness is acceptable, i think.
			So(removed, ShouldResemble, []string{
				"/opt/kite/klient/klient",
				"/opt/kite/klient/klient.sh",
				"/opt/kite/klient",
				"/opt/kite",
				"/usr/local/bin/kd",
			})
		})
	})
}
