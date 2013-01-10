package main

import (
	"bytes"
	"koding/config"
	"koding/tools/dnode"
	"koding/tools/kite"
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
	session          *kite.Session
	remote           dnode.Remote
	pty              *pty.PTY
	process          *os.Process
	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
}

func main() {
	utils.Startup("webterm kite", true)

	if config.Current.UseWebsockets {
		runWebsocket()
		return
	}

	k := kite.New("webterm")
	k.Handle("createServer", false, func(args *dnode.Partial, session *kite.Session) (interface{}, error) {
		remote, err := args.Map()
		if err != nil {
			return nil, err
		}
		server := &WebtermServer{session: session}
		server.remote = remote
		session.CloseOnDisconnect(server)
		return server, nil
	})
	k.Run()
}

func (server *WebtermServer) GetSessions(callback dnode.Callback) {
	dir, err := os.Open("/var/run/screen/S-" + server.session.User)
	if err != nil {
		if os.IsNotExist(err) {
			callback(map[string]string{})
			return
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
	callback(sessions)
}

func (server *WebtermServer) CreateSession(name string, sizeX, sizeY float64) {
	server.runScreen([]string{"-S", name}, sizeX, sizeY)
}

func (server *WebtermServer) JoinSession(sessionId, sizeX, sizeY float64) {
	server.runScreen([]string{"-x", strconv.Itoa(int(sessionId))}, sizeX, sizeY)
}

func (server *WebtermServer) runScreen(args []string, sizeX, sizeY float64) {
	if server.pty != nil {
		panic("Trying to open more than one session.")
	}

	command := []string{"/bin/bash", "-l"}
	// command = append(command, args...)

	pty := pty.New()
	server.pty = pty
	server.SetSize(sizeX, sizeY)

	cmd := server.session.CreateCommand(command...)
	pty.AdaptCommand(cmd)
	err := cmd.Start()
	if err != nil {
		panic(err)
	}
	server.process = cmd.Process

	go func() {
		defer log.RecoverAndLog()

		cmd.Wait()
		pty.Master.Close()
		pty.Slave.Close()
		server.pty = nil
		server.process = nil
		server.remote["sessionEnded"].(dnode.Callback)()
	}()

	go func() {
		defer log.RecoverAndLog()

		buf := make([]byte, (1<<12)-4, 1<<12)
		runes := make([]rune, 1<<12)
		for {
			n, err := pty.Master.Read(buf)
			for n < cap(buf)-1 {
				r, _ := utf8.DecodeLastRune(buf[:n])
				if r != utf8.RuneError {
					break
				}
				pty.Master.Read(buf[n : n+1])
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

			// convert manually to fix invalid utf-8 chars
			i := 0
			c := 0
			for {
				r, l := utf8.DecodeRune(buf[i:n])
				if l == 0 {
					break
				}
				if r >= 0xD800 {
					r = utf8.RuneError
				}
				runes[c] = r
				i += l
				c++
			}

			server.remote["output"].(dnode.Callback)(string(runes[:c]))
			if err != nil {
				break
			}
		}
	}()

	server.remote["sessionStarted"].(dnode.Callback)()
}

func (server *WebtermServer) Input(data string) {
	if server.pty != nil {
		server.pty.Master.Write([]byte(data))
	}
}

func (server *WebtermServer) ControlSequence(data string) {
	if server.pty != nil {
		server.pty.MasterEncoded.Write([]byte(data))
	}
}

func (server *WebtermServer) SetSize(x, y float64) {
	if server.pty != nil {
		server.pty.SetSize(uint16(x), uint16(y))
	}
}

func (server *WebtermServer) Close() error {
	if server.process != nil {
		server.process.Signal(syscall.SIGHUP)
	}
	return nil
}
