package main

import (
	"bytes"
	"errors"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/log"
	"koding/tools/pty"
	"koding/tools/utils"
	"koding/virt"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unicode/utf8"
)

const sessionPrefix = "koding"

type WebtermServer struct {
	Session          string `json:"session"`
	remote           WebtermRemote
	vm               *virt.VM
	user             *virt.User
	isForeignSession bool
	pty              *pty.PTY
	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
}

type WebtermRemote struct {
	Output       dnode.Callback
	SessionEnded dnode.Callback
}

// screenSessions returns a list of sessions that belongs to the given vos
// context. The sessions are in the form of ["k7sdjv12344", "askIj12sas12", ...]
func screenSessions(vos *virt.VOS) []string {
	// Do not include dead sessions in our result
	vos.VM.AttachCommand(vos.User.Uid, "", "screen", "-wipe").Output()

	// We need to use ls here, because /var/run/screen mount is only
	// visible from inside of container. Errors are ignored.
	out, _ := vos.VM.AttachCommand(vos.User.Uid, "", "ls", "/var/run/screen/S-"+vos.User.Name).Output()
	shellOut := string(bytes.TrimSpace(out))
	if shellOut == "" {
		return []string{}
	}

	names := strings.Split(shellOut, "\n")
	sessions := make([]string, len(names))

	prefix := sessionPrefix + "."
	for i, name := range names {
		segments := strings.SplitN(name, ".", 2)
		sessions[i] = strings.TrimPrefix(segments[1], prefix)
	}

	return sessions
}

// screenExists checks whether the given session exists in the running list of
// screen sessions.
func sessionExists(vos *virt.VOS, session string) bool {
	for _, s := range screenSessions(vos) {
		if s == session {
			return true
		}
	}

	return false
}

func registerWebtermMethods(k *kite.Kite) {
	registerVmMethod(k, "webterm.getSessions", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		sessions := screenSessions(vos)
		if len(sessions) == 0 {
			return nil, errors.New("no sessions available")
		}

		return sessions, nil
	})

	// this method is special cased in oskite.go to allow foreign access
	registerVmMethod(k, "webterm.connect", false, func(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
		var params struct {
			Remote       WebtermRemote
			Session      string
			SizeX, SizeY int
			Mode         string
		}

		if args.Unmarshal(&params) != nil || params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{Expected: "{ remote: [object], session: [string], sizeX: [integer], sizeY: [integer], noScreen: [boolean] }"}
		}

		cmdArgs := []string{"/usr/bin/screen", "-e^Bb", "-S"}

		switch params.Mode {
		case "shared", "resume":
			if params.Session == "" {
				return nil, &kite.ArgumentError{Expected: "{ session: [string] }"}
			}

			if !sessionExists(vos, params.Session) {
				return nil, &kite.Error{
					Message: fmt.Sprintf("The given session '%s' is not available.", params.Session),
				}
			}

			cmdArgs = append(cmdArgs, sessionPrefix+"."+params.Session)
			if params.Mode == "shared" {
				cmdArgs = append(cmdArgs, "-x") // multiuser mode
			} else if params.Mode == "resume" {
				cmdArgs = append(cmdArgs, "-dr") // resume
			}
		case "noscreen":
			cmdArgs = nil
		case "create":
			params.Session = utils.RandomString()
			cmdArgs = append(cmdArgs, sessionPrefix+"."+params.Session)
		default:
			return nil, &kite.ArgumentError{Expected: "{ mode: [shared|noscreen|resume|create] }"}
		}

		server := &WebtermServer{
			Session:          params.Session,
			remote:           params.Remote,
			vm:               vos.VM,
			user:             vos.User,
			isForeignSession: vos.User.Name != channel.Username,
			pty:              pty.New(vos.VM.PtsDir()),
		}

		server.SetSize(float64(params.SizeX), float64(params.SizeY))
		server.pty.Slave.Chown(vos.User.Uid, -1)

		cmd := vos.VM.AttachCommand(vos.User.Uid, "/dev/pts/"+strconv.Itoa(server.pty.No), cmdArgs...)
		err := cmd.Start()
		if err != nil {
			panic(err)
		}

		go func() {
			defer log.RecoverAndLog()

			cmd.Wait()
			server.pty.Slave.Close()
			server.pty.Master.Close()
			server.remote.SessionEnded()
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

				server.remote.Output(string(utils.FilterInvalidUTF8(buf[:n])))
				if err != nil {
					break
				}
			}
		}()

		channel.OnDisconnect(func() { server.Close() })

		return server, nil
	})
}

func (server *WebtermServer) Input(data string) {
	server.pty.Master.Write([]byte(data))
}

func (server *WebtermServer) ControlSequence(data string) {
	server.pty.MasterEncoded.Write([]byte(data))
}

func (server *WebtermServer) SetSize(x, y float64) {
	server.pty.SetSize(uint16(x), uint16(y))
}

func (server *WebtermServer) Close() error {
	server.pty.Signal(syscall.SIGHUP)
	return nil
}

func (server *WebtermServer) Terminate() error {
	server.Close()
	if !server.isForeignSession {
		server.vm.AttachCommand(server.user.Uid, "", "/usr/bin/screen", "-S", "koding."+server.Session, "-X", "quit").Run()
	}
	return nil
}
