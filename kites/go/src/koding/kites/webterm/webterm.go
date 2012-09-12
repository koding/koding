package main

import (
	"code.google.com/p/go.net/websocket"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/log"
	"koding/tools/pty"
	"math/rand"
	"net/http"
	"os"
	"os/user"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unicode/utf8"
)

type WebtermServer struct {
	user    string
	remote  dnode.Remote
	pty     *pty.PTY
	process *os.Process
}

var config Config

func init() {
	rand.Seed(time.Now().UnixNano())
	log.Facility = fmt.Sprintf("webterm kite %d", os.Getpid())

	if os.Getuid() != 0 {
		panic("Must be run as root.")
	}

	profile := "default"
	if len(os.Args) >= 2 {
		profile = os.Args[1]
	}

	var ok bool
	config, ok = configs[profile]
	if !ok {
		panic("Configuration not found.")
	}
}

func main() {
	if !config.useWebsockets {

		kite.Start(config.amqpUrl, "webterm", func(user, method string, args interface{}) interface{} {
			if method == "createServer" {
				server := &WebtermServer{user: user}
				server.remote = args.(map[string]interface{})
				return server
			} else {
				panic(fmt.Sprintf("Unknown method: %v.", method))
			}
			return nil
		})

	} else {

		fmt.Println("WebSocket server started. Please open terminal.html in your browser.")
		http.Handle("/", websocket.Handler(func(ws *websocket.Conn) {
			fmt.Printf("WebSocket opened: %p\n", ws)

			server := &WebtermServer{user: config.user}
			defer func() {
				if server.process != nil {
					server.process.Signal(syscall.SIGHUP)
				}
			}()

			node := dnode.New(ws)
			node.SendRemote(server)
			node.OnRemote = func(remote dnode.Remote) {
				server.remote = remote
			}
			node.Run()

			fmt.Printf("WebSocket closed: %p\n", ws)
		}))
		err := http.ListenAndServe(":8080", nil)
		if err != nil {
			panic(err)
		}

	}
}

func (server *WebtermServer) GetSessions(callback dnode.Callback) {
	dir, err := os.Open("/var/run/screen/S-" + server.user)
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

	userData, err := user.Lookup(server.user)
	if err != nil {
		panic(err)
	}
	uid, err := strconv.Atoi(userData.Uid)
	if err != nil {
		panic(err)
	}
	gid, err := strconv.Atoi(userData.Gid)
	if err != nil {
		panic(err)
	}
	if uid == 0 || gid == 0 {
		panic("SECURITY BREACH: User lookup returned root.")
	}

	command := config.shellCommand
	// command = append(command, args...)

	pty := pty.New(uid)
	server.pty = pty
	server.SetSize(sizeX, sizeY)

	process, err := server.pty.StartProcess(
		command,
		&os.ProcAttr{
			Dir: config.homePrefix + server.user,
			Env: []string{
				"USER=" + server.user,
				"LOGNAME=" + server.user,
				"HOME=" + config.homePrefix + server.user,
				"SHELL=/bin/bash",
				"TERM=xterm",
				"LANG=en_US.UTF-8",
				"PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:" + config.homePrefix + server.user + "/bin",
			},
			Sys: &syscall.SysProcAttr{
				Setsid: true,
				Credential: &syscall.Credential{
					Uid: uint32(uid),
					Gid: uint32(gid),
				},
			},
		})
	if err != nil {
		panic(err)
	}
	server.process = process

	go func() {
		defer log.RecoverAndLog()

		process.Wait()
		pty.Master.Close()
		pty.Slave.Close()
		server.pty = nil
		server.process = nil
		server.remote["sessionEnded"].(dnode.Callback)()
	}()

	go func() {
		defer log.RecoverAndLog()

		buf := make([]byte, 1<<12, (1<<12)+4)
		for {
			n, err := pty.Master.Read(buf)
			for {
				r, _ := utf8.DecodeLastRune(buf[:n])
				if r != utf8.RuneError {
					break
				}
				pty.Master.Read(buf[n : n+1])
				n += 1
			}
			server.remote["output"].(dnode.Callback)(string(buf[:n]))
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
