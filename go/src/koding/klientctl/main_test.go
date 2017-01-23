package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	stdlog "log"
	"os"
	"os/exec"
	"sync"
	"testing"

	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

func TestMainHelper(t *testing.T) {
	if os.Getenv("TEST_MAIN_HELPER") == "" {
		return
	}

	// Close stdout as soon as command finishes, so Go's testing command
	// does not pollute it.
	defer os.Stdout.Close()

	ctlcli.ExitFunc = func(code int) {
		if code != 0 {
			os.Exit(code)
		}
	}

	var args []string

	for i, arg := range os.Args {
		if arg == "--" {
			args = os.Args[i+1:]
			break
		}
	}

	if ft := NewFakeTransport(os.Getenv("TEST_MAIN_HELPER_FAKETRANSPORT")); ft != nil {
		testKloudHook = func(client *kloud.Client) {
			client.Transport = ft
		}

		defer func() {
			testKloudHook = nop
		}()
	}

	run(append(os.Args[:1], args...))
}

type MainCmd struct {
	Stdin  io.Reader
	Stdout io.Writer
	Stderr io.Writer
	Home   string

	FT FakeTransport

	once   sync.Once // for mc.init()
	rmHome bool
}

func (mc *MainCmd) Run(args ...string) error {
	mc.init()

	args = append([]string{"-test.run=TestMainHelper", "--"}, args...)

	cmd := exec.Command(os.Args[0], args...)

	cmd.Stdin = mc.Stdin
	cmd.Stdout = mc.Stdout
	cmd.Stderr = mc.Stderr

	// Do not share konfig.bolt between test runs.
	cmd.Env = append(os.Environ(),
		"TEST_MAIN_HELPER=1",
		"KODING_HOME="+mc.Home,
		"KD_EXPERIMENTAL=1",
	)

	if s := mc.FT.String(); s != "" {
		cmd.Env = append(cmd.Env, "TEST_MAIN_HELPER_FAKETRANSPORT="+s)
	}

	return cmd.Run()
}

func (mc *MainCmd) New() *MainCmd {
	mc.init()

	return &MainCmd{
		Home: mc.Home,
	}
}

func (mc *MainCmd) Close() (err error) {
	if mc.Home != "" && mc.rmHome {
		err = os.RemoveAll(mc.Home)
	}
	return err
}

func (mc *MainCmd) init() {
	mc.once.Do(mc.initHome)
}

func (mc *MainCmd) initHome() {
	if mc.Home == "" {
		dir, err := ioutil.TempDir("", "maincmd")
		if err != nil {
			panic("unable to create temp directory: " + err.Error())
		}
		mc.Home = dir
		mc.rmHome = true
	}
}

type FakeTransport struct {
	Responses map[string][]json.RawMessage
}

var _ kloud.Transport = (*FakeTransport)(nil)

func NewFakeTransport(responses string) *FakeTransport {
	if responses == "" {
		return nil
	}

	if p, err := base64.RawStdEncoding.DecodeString(responses); err == nil && len(p) != 0 {
		var ft FakeTransport

		if err := json.Unmarshal(p, &ft.Responses); err == nil && len(ft.Responses) != 0 {
			return &ft
		}
	}

	return nil
}

func (ft *FakeTransport) Add(method string, replies ...interface{}) error {
	if ft.Responses == nil {
		ft.Responses = make(map[string][]json.RawMessage)
	}

	responses := ft.Responses[method]

	for _, reply := range replies {
		p, err := json.Marshal(reply)
		if err != nil {
			return err
		}

		responses = append(responses, json.RawMessage(p))
	}

	ft.Responses[method] = responses

	return nil
}

func (ft *FakeTransport) String() string {
	if len(ft.Responses) == 0 {
		return ""
	}

	p, err := json.Marshal(ft.Responses)
	if err != nil {
		return ""
	}

	return base64.RawStdEncoding.EncodeToString(p)
}

func (ft *FakeTransport) Call(method string, arg, reply interface{}) error {
	responses, ok := ft.Responses[method]
	if !ok || len(responses) == 0 {
		return fmt.Errorf("no response available for %q method", method)
	}

	if reply != nil {
		if err := json.Unmarshal([]byte(responses[0]), reply); err != nil {
			return err
		}
	}

	if testing.Verbose() {
		stdlog.Printf("FakeTransport: method=%q, arg=%#v, reply=%#v", method, arg, reply)
	}

	ft.Responses[method] = responses[1:]

	return nil
}

func (ft *FakeTransport) Connect(string) (kloud.Transport, error) { return ft, nil }

func (*FakeTransport) Valid() (_ error) { return }

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
