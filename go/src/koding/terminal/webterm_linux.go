package terminal

import (
	"bytes"
	"fmt"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/pty"
	"koding/tools/utils"
	"koding/virt"
	"os"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unicode/utf8"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	sessionPrefix     = "koding"
	kodingScreenPath  = "/opt/koding/bin/screen"
	kodingScreenrc    = "/opt/koding/etc/screenrc"
	defaultScreenPath = "/usr/bin/screen"
)

var (
	ErrNoSession      = "ErrNoSession"
	ErrInvalidSession = "ErrInvalidSession"
)

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
	screenPath       string
	throttling       bool
}

type WebtermRemote struct {
	Output       dnode.Callback
	SessionEnded dnode.Callback
}

func webtermPing(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return "pong", nil
}

func webtermKillSession(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Session string
	}

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{ session: [string]}"}
	}

	if err := killSession(vos, params.Session); err != nil {
		return nil, err
	}

	return true, nil
}

func webtermGetSessions(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	sessions := screenSessions(vos)
	if len(sessions) == 0 {
		return nil, &kite.BaseError{
			Message: "No sessions available",
			CodeErr: ErrNoSession,
		}
	}

	return sessions, nil
}

// this method is special cased in oskite.go to allow foreign access
func webtermConnect(args *dnode.Partial, channel *kite.Channel, vos *virt.VOS) (interface{}, error) {
	var params struct {
		Remote       WebtermRemote
		Session      string
		SizeX, SizeY int
		Mode         string
		JoinUser     string
	}

	if args == nil {
		return nil, &kite.ArgumentError{Expected: "empty argument passed"}
	}

	if err := args.Unmarshal(&params); err != nil {
		return nil, kite.NewKiteErr(err)
	}

	if params.JoinUser != "" {
		if len(params.Session) != utils.RandomStringLength {
			return nil, &kite.BaseError{
				Message: "Invalid session identifier",
				CodeErr: ErrInvalidSession,
			}
		}

		user := new(virt.User)
		if err := mongodbConn.Run("jUsers", func(c *mgo.Collection) error {
			return c.Find(bson.M{"username": params.JoinUser}).One(user)
		}); err != nil {
			return nil, err
		}

		// vos.VM is replaced already in registerMethod via
		// channel.CorrelationName which is the remote VM hostnameAlias
		vos.User = user
	}

	screen, err := newScreen(vos, params.Mode, params.Session)
	if err != nil {
		return nil, err
	}

	server := &WebtermServer{
		Session:          screen.Session,
		remote:           params.Remote,
		vm:               vos.VM,
		user:             vos.User,
		isForeignSession: vos.User.Name != channel.Username,
		pty:              pty.New(vos.VM.PtsDir()),
		screenPath:       screen.ScreenPath,
		throttling:       false,
	}

	if params.Mode != "resume" || params.Mode != "shared" {
		if params.SizeX <= 0 || params.SizeY <= 0 {
			return nil, &kite.ArgumentError{Expected: "{ sizeX: [integer], sizeY: [integer] }"}
		}

		server.SetSize(float64(params.SizeX), float64(params.SizeY))
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

			server.remote.Output(string(utils.FilterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
	}()

	channel.OnDisconnect(func() { server.Close() })

	return server, nil
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
		server.vm.AttachCommand(server.user.Uid, "", server.screenPath, "-S", sessionPrefix+"."+server.Session, "-X", "quit").Run()
	}
	return nil
}

type screen struct {
	// Binary used for starting the screen
	ScreenPath string

	// Used for remote or multiuser mode, defines the custom session name
	Session string

	// the final command to be executed
	Command []string
}

func getScreenPath(vos *virt.VOS) (string, error) {
	screenPath := kodingScreenPath

	// it can happen that the user deleted our screen binary
	// accidently, if this happens fallback to default screen binary
	_, err := vos.Stat(kodingScreenPath)
	if err != nil {
		log.Warning("vos.Stat kodingScreenPath %v, failing over to default screen path", err)
	}

	if os.IsNotExist(err) {
		// check if the default screen binary exists too
		_, err := vos.Stat(defaultScreenPath)
		if err != nil {
			log.Error("vos.Stat defaultScreenPath %v", err)
		} else {
			log.Info("vos.Stat success defaultScreenPath found %s", defaultScreenPath)
		}

		if os.IsNotExist(err) {
			return "", &kite.BaseError{
				Message: fmt.Sprintf("neither %s nor %s does exist.", kodingScreenPath, defaultScreenPath),
				CodeErr: ErrInvalidSession,
			}
		}

		screenPath = defaultScreenPath
	}

	return screenPath, nil
}

// newScreen returns a new screen instance that is used to start screen. The
// screen command line is created differently based on the incoming mode.
func newScreen(vos *virt.VOS, mode, session string) (*screen, error) {
	var screenPath string
	var err error
	attempts := 0

	// we do try several trimes to get the binary path because the VM might not
	// up immedieately.
	for {
		screenPath, err = getScreenPath(vos)
		if err == nil {
			break
		}

		// try 4 times before we hit our 15 sec timeout limit
		if attempts != 4 {
			time.Sleep(time.Second * 3) // wait a little bit ...
			attempts++
			continue
		}

		return nil, fmt.Errorf("tried five times: %s", err)
	}

	cmdArgs := []string{screenPath, "-c", kodingScreenrc, "-S"}

	// check also if our custom screenrc exists before we continue
	_, err = vos.Stat(kodingScreenrc)
	if os.IsNotExist(err) {
		log.Warning("Screenrc %s does not exist. Starting screen without screenrc.", kodingScreenrc)
		cmdArgs = []string{screenPath, "-S"}
	}

	log.Info("Mode: %s", mode)

	switch mode {
	case "shared", "resume":
		if session == "" {
			return nil, &kite.ArgumentError{Expected: "{ session: [string] }"}
		}

		if !sessionExists(vos, session) {
			return nil, &kite.BaseError{
				Message: fmt.Sprintf("The given session '%s' is not available.", session),
				CodeErr: ErrInvalidSession,
			}
		}

		cmdArgs = append(cmdArgs, sessionPrefix+"."+session)
		if mode == "shared" {
			cmdArgs = append(cmdArgs, "-x") // multiuser mode
		} else if mode == "resume" {
			cmdArgs = append(cmdArgs, "-raAd") // resume
		}
	case "noscreen":
		cmdArgs = nil
	case "create":
		session = utils.RandomString()
		cmdArgs = append(cmdArgs, sessionPrefix+"."+session)
	default:
		return nil, &kite.ArgumentError{Expected: "{ mode: [shared|noscreen|resume|create] }"}
	}

	s := &screen{
		ScreenPath: screenPath,
		Session:    session,
		Command:    cmdArgs,
	}

	return s, nil
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

// killSession kills the given SessionID
func killSession(vos *virt.VOS, sessionID string) error {
	screenPath, err := getScreenPath(vos)
	if err != nil {
		return err
	}

	out, err := vos.VM.AttachCommand(vos.User.Uid, "", screenPath, "-X", "-S", sessionPrefix+"."+sessionID, "kill").Output()
	if err != nil {
		return commandError("screen kill failed", err, out)
	}

	return nil
}

func commandError(message string, err error, out []byte) error {
	return fmt.Errorf("%s\n%s\n%s", message, err.Error(), string(out))
}
