package main

import (
	"io/ioutil"
	"os"
	"path"
	"testing"

	"koding/kites/tunnelproxy/discover/discovertest"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/restypes"
	"koding/klient/util"
	"koding/klientctl/klient"
	"koding/klientctl/list"
	"koding/klientctl/ssh"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSSHCommand(t *testing.T) {
	Convey("", t, func() {
		tempSSHDir, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)
		defer os.Remove(tempSSHDir)

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

				Convey("It should return ErrRemoteDialingFailed", func() {
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
			So(os.IsExist(err), ShouldBeFalse)
		})

		Convey("It should create ssh folder if it doesn't exist", func() {
			So(s.PrepareForSSH("name"), ShouldBeNil)

			_, err := os.Stat(s.KeyPath)
			So(err, ShouldBeNil)
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
	})
}

func TestSSHKey(t *testing.T) {
	Convey("It should discover remote IP for tunneled connection", t, func() {
		srv := discovertest.Server{
			"ssh": {{
				Addr:  "apple.rafal.grape.koding.me:2222",
				Local: false,
			}},
		}

		l, err := srv.Start()
		So(err, ShouldBeNil)
		defer l.Close()

		k := &fakeKlient{
			Remotes: list.KiteInfos{{
				ListMachineInfo: restypes.ListMachineInfo{
					Hostname: "root",
					VMName:   "remote",
					IP:       l.Addr().String(),
				},
			}},
		}

		s := ssh.SSHKey{
			Klient: k,
		}

		userhost, port, err := s.GetSSHAddr("remote")
		So(err, ShouldBeNil)
		So(userhost, ShouldEqual, "root@apple.rafal.grape.koding.me")
		So(port, ShouldEqual, "2222")
	})

	Convey("It should discover local IP for tunneled connection", t, func() {
		srv := discovertest.Server{
			"ssh": {{
				Addr:  "127.0.0.1:2222",
				Local: true,
			}},
		}

		l, err := srv.Start()
		So(err, ShouldBeNil)
		defer l.Close()

		k := &fakeKlient{
			Remotes: list.KiteInfos{{
				ListMachineInfo: restypes.ListMachineInfo{
					Hostname: "root",
					VMName:   "local",
					IP:       l.Addr().String(),
				},
			}},
		}

		s := ssh.SSHKey{
			Klient: k,
		}

		userhost, port, err := s.GetSSHAddr("local")
		So(err, ShouldBeNil)
		So(userhost, ShouldEqual, "root@127.0.0.1")
		So(port, ShouldEqual, "2222")
	})
}
