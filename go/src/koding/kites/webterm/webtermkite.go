package main

import (
	"bytes"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/lifecycle"
	"koding/tools/log"
	"koding/tools/pty"
	"koding/tools/utils"
	"os"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unicode/utf8"
)

type WebtermServer struct {
	remote           WebtermRemote
	pty              *pty.PTY
	process          *os.Process
	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
}

type WebtermRemote struct {
	Output       dnode.Callback
	SessionEnded dnode.Callback
}

func main() {
	lifecycle.Startup("kite.webterm", true)

	k := kite.New("webterm")

	k.Handle("getSessions", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		dir, err := os.Open("/var/run/screen/S-" + session.User)
		if err != nil {
			if os.IsNotExist(err) {
				return make(map[string]string), nil
			}
			panic(err)
		}
		names, err := dir.Readdirnames(0)
		if err != nil {
			panic(err)
		}
		sessions := make(map[string]string)
		for _, name := range names {
			parts := strings.SplitN(name, ".", 2)
			sessions[parts[0]] = parts[1]
		}
		return sessions, nil
	})

	k.Handle("createSession", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Remote       WebtermRemote
			Name         string
			SizeX, SizeY int
		}
		if args.Unmarshal(&params) != nil || params.Name == "" || params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{"{ remote: [object], name: [string], sizeX: [integer], sizeY: [integer] }"}
		}

		return newWebtermServer(session, params.Remote, []string{"-S", params.Name}, params.SizeX, params.SizeY), nil
	})

	k.Handle("joinSession", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		var params struct {
			Remote       WebtermRemote
			SessionId    int
			SizeX, SizeY int
		}
		if args.Unmarshal(&params) != nil || params.SessionId <= 0 || params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{"{ remote: [object], sessionId: [integer], sizeX: [integer], sizeY: [integer] }"}
		}

		return newWebtermServer(session, params.Remote, []string{"-x", strconv.Itoa(int(params.SessionId))}, params.SizeX, params.SizeY), nil
	})

	k.Run()
}

func newWebtermServer(session *kite.Session, remote WebtermRemote, args []string, sizeX, sizeY int) *WebtermServer {
	server := &WebtermServer{
		remote: remote,
		pty:    pty.New(pty.DefaultPtsPath),
	}
	server.SetSize(float64(sizeX), float64(sizeY))
	session.CloseOnDisconnect(server)

	command := []string{"/bin/bash", "-l"}
	// command = append(command, args...)
	cmd := session.CreateCommand(command...)
	server.pty.Slave.Chown(int(cmd.SysProcAttr.Credential.Uid), -1)
	cmd.Stdin = server.pty.Slave
	cmd.Stdout = server.pty.Slave
	cmd.Stderr = server.pty.Slave
	cmd.SysProcAttr.Setsid = true
	err := cmd.Start()
	if err != nil {
		panic(err)
	}
	server.process = cmd.Process

	go func() {
		defer log.RecoverAndLog()

		cmd.Wait()
		server.pty.Master.Close()
		server.pty.Slave.Close()
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

	return server
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
	server.process.Signal(syscall.SIGHUP)
	return nil
}
