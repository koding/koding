package main

import (
	"bytes"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"koding/kite"
	"koding/kite/dnode"
	"koding/tools/pty"
	"os/exec"
	"os/user"
	"syscall"
	"time"
	"unicode/utf8"
)

func main() {
	NewTerminal().Run()
}

func NewTerminal() *kite.Kite {
	options := &kite.Options{
		Kitename:    "terminal",
		Version:     "0.0.1",
		Region:      "localhost",
		Environment: "development",
	}

	k := kite.New(options)
	k.DisableConcurrency()
	k.HandleFunc("connect", Connect)
	return k
}

func Connect(r *kite.Request) (interface{}, error) {
	var params struct {
		Remote       WebtermRemote
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
	server := &WebtermServer{
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
		server.remote.SessionEnded()
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

			server.remote.Output(string(FilterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
	}()

	return server, nil
}

// WebtermServer is the type of object that is sent to the connected client.
// Represents a running shell process on the server.
type WebtermServer struct {
	Session          string `json:"session"`
	remote           WebtermRemote
	isForeignSession bool
	pty              *pty.PTY
	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
}

type WebtermRemote struct {
	Output       dnode.Function
	SessionEnded dnode.Function
}

// Input is called when some text is written to the terminal.
func (w *WebtermServer) Input(req *kite.Request) {
	data := req.Args.One().MustString()

	// There is no need to protect the Write() with a mutex because
	// Kite Library guarantees that only one message is processed at a time.
	w.pty.Master.Write([]byte(data))
}

// ControlSequence is called when a non-printable key is pressed on the terminal.
func (w *WebtermServer) ControlSequence(req *kite.Request) {
	data := req.Args.One().MustString()
	w.pty.MasterEncoded.Write([]byte(data))
}

func (w *WebtermServer) SetSize(req *kite.Request) {
	args := req.Args.MustSliceOfLength(2)
	x := args[0].MustFloat64()
	y := args[1].MustFloat64()
	w.setSize(x, y)
}

func (w *WebtermServer) setSize(x, y float64) {
	w.pty.SetSize(uint16(x), uint16(y))
}

func (w *WebtermServer) Close(req *kite.Request) {
	w.pty.Signal(syscall.SIGHUP)
}

func (w *WebtermServer) Terminate(req *kite.Request) {
	w.Close(nil)
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
