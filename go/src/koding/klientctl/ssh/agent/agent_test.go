package agent

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

const outputDarwin = `
SSH_AUTH_SOCK=/var/folders/67/something.36749; export SSH_AUTH_SOCK;
SSH_AGENT_PID=36750; export SSH_AGENT_PID;
echo Agent pid 36750;
`

func TestClient(t *testing.T) {
	Convey("Client", t, func() {
		m := &Client{
			binRunner: generateBinRunner(outputDarwin),
		}

		Convey("It should return ssh auth sock", func() {
			path, err := m.GetAuthSock()
			So(err, ShouldBeNil)
			So(path, ShouldEqual, "/var/folders/67/something.36749")
		})

		Convey("It should return ssh agent pid", func() {
			pid, err := m.GetAgentPid()
			So(err, ShouldBeNil)
			So(pid, ShouldEqual, "36750")
		})
	})
}

func generateBinRunner(s string) func(string) (string, error) {
	return func(string) (string, error) {
		return s, nil
	}
}
