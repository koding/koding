package main

import (
	"io/ioutil"
	"os"
	"path"
	"testing"

	"koding/klient/kiteerrortypes"
	"koding/klient/util"
	"koding/klientctl/klient"
	"koding/klientctl/ssh"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSSHCommand(t *testing.T) {
	Convey("", t, func() {
		tempSSHDir, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)

		teller := newFakeTransport()
		s := ssh.SSHCommand{
			SSHKey: &ssh.SSHKey{
				KeyPath: tempSSHDir,
				KeyName: "key",
				// Create a klient, with the fake transport to satisfy the Teller interface.
				Klient: &klient.Klient{
					Teller: teller,
				},
			},
		}

		Convey("Given PrepareForSSH is called", func() {
			Convey("When it returns a dialing error", func() {
				kiteErr := util.KiteErrorf(
					kiteerrortypes.DialingFailed, "Failed to dial.",
				)
				teller.TripErrors["remote.sshKeysAdd"] = kiteErr

				Convey("It should return ErrDialingFailed", func() {
					So(s.PrepareForSSH("foo"), ShouldEqual, kiteErr)
				})
			})
		})

		Convey("It should return public key path", func() {
			key := s.PublicKeyPath()
			So(key, ShouldEqual, path.Join(tempSSHDir, "key.pub"))
		})

		Convey("It should return private key path", func() {
			key := s.PrivateKeyPath()
			So(key, ShouldEqual, path.Join(tempSSHDir, "key"))
		})

		Convey("It should return error if invalid key exists", func() {
			err := ioutil.WriteFile(s.PrivateKeyPath(), []byte("a"), 0700)
			So(err, ShouldBeNil)

			err = ioutil.WriteFile(s.PublicKeyPath(), []byte("a"), 0700)
			So(err, ShouldBeNil)

			err = s.PrepareForSSH("name")
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "ssh: no key found")
		})

		Convey("It generates and saves key to remote if key doesn't exist", func() {
			err := s.PrepareForSSH("name")
			So(err, ShouldBeNil)

			firstContents, err := ioutil.ReadFile(s.PublicKeyPath())
			So(err, ShouldBeNil)

			publicExists := s.PublicKeyExists()
			So(publicExists, ShouldBeTrue)

			privateExists := s.PrivateKeyExists()
			So(privateExists, ShouldBeTrue)

			Convey("It returns key if it exists", func() {
				err := s.PrepareForSSH("name")
				So(err, ShouldBeNil)

				secondContents, err := ioutil.ReadFile(s.PublicKeyPath())
				So(err, ShouldBeNil)

				So(string(firstContents), ShouldEqual, string(secondContents))
			})
		})

		defer os.Remove(tempSSHDir)
	})
}
