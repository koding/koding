package terminal

import (
	"bytes"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"koding/tools/pty"
	"os/exec"
	"os/user"
	"syscall"
	"time"
	"unicode/utf8"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

// Server is the type of object that is sent to the connected client.
// Represents a running shell process on the server.
type Server struct {
	Session          string `json:"session"`
	remote           Remote
	isForeignSession bool
	pty              *pty.PTY
	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
}

type Remote struct {
	Output       dnode.Function
	SessionEnded dnode.Function
}

func Connect(r *kite.Request) (interface{}, error) {
	var params struct {
		Remote       Remote
		Session      string
		SizeX, SizeY int
		NoScreen     bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.SizeX <= 0 || params.SizeY <= 0 {
		return nil, errors.New("{ remote: [object], session: [string], sizeX: [integer], sizeY: [integer], noScreen: [boolean] }")
	}

	if params.NoScreen && params.Session != "" {
		return nil, errors.New("The 'noScreen' and 'session' parameters can not be used together.")
	}

	newSession := false
	if params.Session == "" {
		// TODO: Check that if it is possible to change the session key with
		// an incrementing integer because random string looks ugly in "ps" command output.
		params.Session = RandomString()
		newSession = true
	}

	// We will return this object to the client.
	server := &Server{
		Session: params.Session,
		remote:  params.Remote,
		pty:     pty.New("/dev/pts"),
	}

	server.setSize(float64(params.SizeX), float64(params.SizeY))

	var command struct {
		name string
		args []string
	}

	command.name = "/usr/bin/screen"
	command.args = []string{"-e^Bb", "-s", "/bin/bash", "-S", "koding." + params.Session}
	// tmux version, attach to an existing one, if not available it creates one
	// command.name = "/usr/local/bin/tmux"
	// command.args = []string{"tmux", "attach", "-t", "koding." + params.Session, "||", "tmux", "new-session", "-s", "koding." + params.Session}

	if !newSession {
		command.args = append(command.args, "-x")
	}

	if params.NoScreen {
		command.name = "/bin/bash"
		command.args = []string{}
	}

	cmd := exec.Command(command.name, command.args...)

	user, err := user.Current()
	if err != nil {
		return nil, fmt.Errorf("Could not get home dir: %s", err)
	}

	cmd.Env = []string{"TERM=xterm-256color", "HOME=" + user.HomeDir}
	cmd.Stdin = server.pty.Slave
	// cmd.Stdout = server.pty.Slave
	// cmd.Stderr = server.pty.Slave

	// Open in background, this is needed otherwise the process will be killed
	// if you hit close on the client side.
	cmd.SysProcAttr = &syscall.SysProcAttr{Setctty: true, Setsid: true}

	err = cmd.Start()
	if err != nil {
		fmt.Println("could not start", err)
	}

	// Wait until the shell process is closed and notify the client.
	go func() {
		err := cmd.Wait()
		if err != nil {
			fmt.Println("cmd.wait err", err)
		}

		server.pty.Slave.Close()
		server.pty.Master.Close()
		server.remote.SessionEnded.Call()
	}()

	// Read the STDOUT from shell process and send to the connected client.
	go func() {
		buf := make([]byte, (1<<12)-utf8.UTFMax, 1<<12)
		for {
			n, err := server.pty.Master.Read(buf)
			for n < cap(buf)-1 {
				r, _ := utf8.DecodeLastRune(buf[:n])
				if r != utf8.RuneError {
					break
				}
				server.pty.Master.Read(buf[n : n+1])
				n++
			}

			// Rate limiting...
			s := time.Now().Unix()
			if server.currentSecond != s {
				server.currentSecond = s
				server.messageCounter = 0
				server.byteCounter = 0
				server.lineFeeedCounter = 0
			}
			server.messageCounter += 1
			server.byteCounter += n
			server.lineFeeedCounter += bytes.Count(buf[:n], []byte{'\n'})
			if server.messageCounter > 100 || server.byteCounter > 1<<18 || server.lineFeeedCounter > 300 {
				time.Sleep(time.Second)
			}

			server.remote.Output.Call(string(FilterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
	}()

	return server, nil
}

// Input is called when some text is written to the terminal.
func (s *Server) Input(d *dnode.Partial) {
	data := d.MustSliceOfLength(1)[0].MustString()

	// There is no need to protect the Write() with a mutex because
	// Kite Library guarantees that only one message is processed at a time.
	s.pty.Master.Write([]byte(data))
}

// ControlSequence is called when a non-printable key is pressed on the terminal.
func (s *Server) ControlSequence(d *dnode.Partial) {
	data := d.MustSliceOfLength(1)[0].MustString()
	s.pty.MasterEncoded.Write([]byte(data))
}

func (s *Server) SetSize(d *dnode.Partial) {
	args := d.MustSliceOfLength(2)
	x := args[0].MustFloat64()
	y := args[1].MustFloat64()
	s.setSize(x, y)
}

func (s *Server) setSize(x, y float64) {
	s.pty.SetSize(uint16(x), uint16(y))
}

func (s *Server) Close(d *dnode.Partial) {
	s.pty.Signal(syscall.SIGHUP)
}

func (s *Server) Terminate(d *dnode.Partial) {
	s.Close(nil)
}

func FilterInvalidUTF8(buf []byte) []byte {
	i := 0
	j := 0
	for {
		r, l := utf8.DecodeRune(buf[i:])
		if l == 0 {
			break
		}
		if r < 0xD800 {
			if i != j {
				copy(buf[j:], buf[i:i+l])
			}
			j += l
		}
		i += l
	}
	return buf[:j]
}

const RandomStringLength = 24 // 144 bit base64 encoded

func RandomString() string {
	r := make([]byte, RandomStringLength*6/8)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}
