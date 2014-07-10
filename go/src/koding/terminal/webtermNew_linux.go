package terminal

import (
	"bytes"
	"errors"
	"fmt"
	"koding/tools/kite"
	"koding/tools/pty"
	"koding/tools/utils"
	"koding/virt"
	"strconv"
	"syscall"
	"time"
	"unicode/utf8"

	kitelib "github.com/koding/kite"
	kitednode "github.com/koding/kite/dnode"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// DO NOT CONFUSE THIS WITH WebtermServer in webterm.go, this is build on top
// of our new kite lib !!!!! - arslan

// WebtermServer is the type of object that is sent to the connected client.
// Represents a running shell process on the server.
type WebtermServerNew struct {
	Session          string `json:"session"`
	remote           WebtermRemoteNew
	vm               *virt.VM
	user             *virt.User
	pty              *pty.PTY
	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
	screenPath       string
	throttling       bool
}

type WebtermRemoteNew struct {
	Output       kitednode.Function
	SessionEnded kitednode.Function
}

func webtermPingNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	return "pong", nil
}

func webtermKillSessionNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Session string
	}

	if r.Args.One().Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{ session: [string] }"}
	}

	if err := killSession(vos, params.Session); err != nil {
		return nil, err
	}

	return true, nil
}

func webtermGetSessionsNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	sessions := screenSessions(vos)
	if len(sessions) == 0 {
		return nil, errors.New("no sessions available")
	}

	return sessions, nil
}

func webtermConnectNew(r *kitelib.Request, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Remote       WebtermRemoteNew
		Session      string
		SizeX, SizeY int
		Mode         string
		JoinUser     string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, kite.NewKiteErr(err)
	}

	if params.JoinUser != "" {
		if len(params.Session) != utils.RandomStringLength {
			return nil, &kite.BaseError{
				Message: "Invalid session identifier",
				CodeErr: ErrInvalidSession,
			}
		}

		fmt.Printf("params %#v\n", params)

		user := new(virt.User)
		if err := mongodbConn.Run("jUsers", func(c *mgo.Collection) error {
			return c.Find(bson.M{"username": params.JoinUser}).One(&user)
		}); err != nil {
			return nil, err
		}

		vos.User = user
	}

	screen, err := newScreen(vos, params.Mode, params.Session)
	if err != nil {
		return nil, err
	}

	server := &WebtermServerNew{
		Session:    screen.Session,
		remote:     params.Remote,
		vm:         vos.VM,
		user:       vos.User,
		pty:        pty.New(vos.VM.PtsDir()),
		screenPath: screen.ScreenPath,
		throttling: true,
	}

	if params.Mode != "resume" || params.Mode != "shared" {
		if params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{Expected: "{ sizeX: [integer], sizeY: [integer] }"}
		}

		server.setSize(float64(params.SizeX), float64(params.SizeY))
	}

	server.pty.Slave.Chown(vos.User.Uid, -1)

	cmd := vos.VM.AttachCommand(vos.User.Uid, "/dev/pts/"+strconv.Itoa(server.pty.No), screen.Command...)
	err = cmd.Start()
	if err != nil {
		return nil, err
	}

	go func() {
		defer log.RecoverAndLog()

		cmd.Wait()
		server.pty.Slave.Close()
		server.pty.Master.Close()
		server.remote.SessionEnded.Call()
	}()

	go func() {
		defer log.RecoverAndLog()

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

			if server.throttling {
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
					time.Sleep(time.Second / 100)
				}
			}

			server.remote.Output.Call(string(utils.FilterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
	}()

	r.Client.OnDisconnect(func() { server.close() })

	return server, nil
}

// Input is called when some text is written to the terminal.
func (w *WebtermServerNew) Input(p *kitednode.Partial) {
	data := p.MustSliceOfLength(1)[0].MustString()

	// There is no need to protect the Write() with a mutex because
	// Kite Library guarantees that only one message is processed at a time.
	w.pty.Master.Write([]byte(data))
}

// ControlSequence is called when a non-printable key is pressed on the terminal.
func (w *WebtermServerNew) ControlSequence(p *kitednode.Partial) {
	data := p.MustSliceOfLength(1)[0].MustString()
	w.pty.MasterEncoded.Write([]byte(data))
}

func (w *WebtermServerNew) SetSize(p *kitednode.Partial) {
	args := p.MustSliceOfLength(2)
	x := args[0].MustFloat64()
	y := args[1].MustFloat64()
	w.setSize(x, y)
}

func (w *WebtermServerNew) setSize(x, y float64) {
	w.pty.SetSize(uint16(x), uint16(y))
}

func (w *WebtermServerNew) close() {
	w.pty.Signal(syscall.SIGHUP)
}

func (w *WebtermServerNew) Close(p *kitednode.Partial) {
	w.pty.Signal(syscall.SIGHUP)
}

func (w *WebtermServerNew) Terminate(p *kitednode.Partial) {
	w.Close(nil)
}
