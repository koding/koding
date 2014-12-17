package terminal

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

func TestTerminal(t *testing.T) {
	terminal := kite.New("terminal", "0.0.1")
	terminal.Config.DisableConcurrency = true
	terminal.Config.DisableAuthentication = true
	terminal.Config.Port = 3636
	terminal.HandleFunc("connect", Connect)

	go terminal.Run()
	<-terminal.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config.DisableAuthentication = true
	remote := client.NewClient("http://127.0.0.1:3636/kite")
	err := remote.Dial()
	if err != nil {
		t.Fatal(err)
	}

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
	term.Input.Call(`say kite`)
	// time.Sleep(100 * time.Millisecond)
	term.ControlSequence.Call("\r")

	// time.Sleep(100 * time.Millisecond)

	term.Input.Call(`python -c "print 123455+1"`)
	// time.Sleep(100 * time.Millisecond)
	term.ControlSequence.Call("\r")

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
