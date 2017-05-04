// +build !windows

package terminal

import (
	"fmt"
	"os/exec"
	"strings"
	"testing"
	"time"

	"koding/klient/testutil"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
)

var testLog = logging.NewCustom("test", true)

func TestTerminal(t *testing.T) {
	kiteURL := testutil.GenKiteURL()

	screen, err := exec.LookPath("screen")
	if err != nil {
		t.Fatalf("unable to find screen: %s", err)
	}

	terminal := kite.New("terminal", "0.0.1")
	terminal.Config.DisableConcurrency = true
	terminal.Config.DisableAuthentication = true
	terminal.Config.Port = kiteURL.Port()

	termInstance := New(testLog, screen)
	terminal.HandleFunc("connect", termInstance.Connect)

	go terminal.Run()
	<-terminal.ServerReadyNotify()
	defer terminal.Close()

	client := kite.New("client", "0.0.1")
	client.Config.DisableAuthentication = true
	client.Log = testLog

	remote := client.NewClient(kiteURL.String())
	err = remote.Dial()
	if err != nil {
		t.Fatal(err)
	}
	defer remote.Close()

	termClient := newTermHandler()

	result, err := remote.Tell("connect", struct {
		Remote       *termHandler
		Session      string
		SizeX, SizeY int
		Mode         string
	}{
		Remote: termClient,
		SizeX:  80,
		SizeY:  24,
		Mode:   "create",
	})
	if err != nil {
		t.Error(err)
		return
	}

	var term *remoteTerm
	err = result.Unmarshal(&term)
	if err != nil {
		t.Error(err.Error())
		return
	}

	// Two commands are run to make sure that the order of the keys are preserved.
	// If not, sometimes inputs are mixed in a way that is non-deterministic.
	err = term.Input.Call(`say kite`)
	if err != nil {
		t.Fatal(err)
	}

	// time.Sleep(100 * time.Millisecond)
	err = term.ControlSequence.Call("\r")
	if err != nil {
		t.Fatal(err)
	}

	// time.Sleep(100 * time.Millisecond)

	err = term.Input.Call(`python -c "print 123455+1"`)
	if err != nil {
		t.Fatal(err)
	}

	// time.Sleep(100 * time.Millisecond)
	err = term.ControlSequence.Call("\r")
	if err != nil {
		t.Fatal(err)
	}

	fullOutput := ""
	for {
		select {
		case output := <-termClient.output:
			// fmt.Printf("Received output from channel: %+v\n", output)
			fullOutput += output
			if strings.Contains(fullOutput, "123456") { // magic number
				return
			}
		case <-time.After(2 * time.Second):
			fmt.Println(fullOutput)
			t.Error("Timeout")
			return
		}
	}
}

type termHandler struct {
	output chan string
}

func newTermHandler() *termHandler {
	return &termHandler{
		output: make(chan string),
	}
}

func (r *termHandler) Output(d *dnode.Partial) {
	data := d.MustSliceOfLength(1)[0].MustString()
	r.output <- data
}

func (r *termHandler) SessionEnded(d *dnode.Partial) {
	fmt.Println("Session ended")
}

type remoteTerm struct {
	Session         string `json:"session"`
	Input           dnode.Function
	ControlSequence dnode.Function
	SetSize         dnode.Function
	Close           dnode.Function
	Terminate       dnode.Function
}
