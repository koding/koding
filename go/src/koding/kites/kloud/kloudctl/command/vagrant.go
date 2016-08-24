package command

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"

	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/keycreator"
	puser "koding/kites/kloud/scripts/provisionklient/userdata"
	"koding/kites/kloud/utils/res"

	"github.com/koding/logging"
	"github.com/mitchellh/cli"
	"github.com/satori/go.uuid"
	"golang.org/x/net/context"
)

const latest = "https://koding-klient.s3.amazonaws.com/development/latest-version.txt"

var (
	defaultHost        = os.Getenv("KLOUDCTL_VAGRANT_HOST")
	defaultUsername    string
	defaultPrivateKey  string
	defaultPublicKey   string
	defaultRegisterURL string // tunnel for 127.0.0.1:56790
	defaultKlientURL   string
)

func init() {
	u, err := user.Current()
	if err != nil {
		log.Println("unable to get current user:", err)
		return
	}

	defaultUsername = u.Username
	defaultRegisterURL = fmt.Sprintf("http://guest-klient-%s.ngrok.com/kite", u.Username)

	p, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		log.Println("unable to get git top dir:", err)
		return
	}

	top := string(bytes.TrimSpace(p))

	credDir := filepath.Join(top, "vault")

	if s := os.Getenv("KLOUDCTL_CREDSDIR"); s != "" {
		credDir = s
	}

	p, err = ioutil.ReadFile(filepath.Join(credDir, "private_keys", "kontrol", "kontrol.pem"))
	if err != nil {
		log.Println("unable to read private key:", err)
		return
	}

	defaultPrivateKey = string(p)

	p, err = ioutil.ReadFile(filepath.Join(credDir, "private_keys", "kontrol", "kontrol.pub"))
	if err != nil {
		log.Println("unable to read private key:", err)
		return
	}

	defaultPublicKey = string(p)

	resp, err := http.Get(latest)
	if err != nil {
		log.Println("unable to get klient latest version:", err)
		return
	}
	if resp.StatusCode != 200 {
		log.Println("unable to get klient latest version:", resp.StatusCode)
		return
	}
	defer resp.Body.Close()

	p, err = ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Println("unable to get klient latest version:", err)
		return
	}

	defaultKlientURL = fmt.Sprintf("https://koding-klient.s3.amazonaws.com/devel"+
		"opment/latest/klient_0.1.%s_development_amd64.deb", bytes.TrimSpace(p))
}

// Vagrant provides an implementation for "vagrant" command.
type Vagrant struct {
	*res.Resource
}

// NewVagrant gives new Vagrant value.
func NewVagrant() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("vagrant", "Client for klient vagrant kite")
		f.action = &Vagrant{
			Resource: &res.Resource{
				Name:        "vagrant",
				Description: "",
				Commands: map[string]res.Command{
					"create":  NewVagrantCreate(),
					"list":    NewVagrantList(),
					"status":  NewVagrantStatus(),
					"version": NewVagrantVersion(),
					"up":      NewVagrantCmd("up"),
					"halt":    NewVagrantCmd("halt"),
					"destroy": NewVagrantCmd("destroy"),
				},
			},
		}
		return f, nil
	}
}

// Action is an entry point for "vagrant" subcommand.
func (v *Vagrant) Action(args []string) error {
	k, err := kloudClient()
	if err != nil {
		return err
	}
	vapi := &vagrantapi.Klient{
		Kite:  k.LocalKite,
		Log:   logging.NewCustom("vagrant", flagDebug),
		Debug: true,
	}

	ctx := context.Background()
	ctx = context.WithValue(ctx, vapiKey, vapi)
	v.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return v.Resource.Main(args)
}

/// VAGRANT CREATE

// VagrantCreate provides an implementation for "vagrant create" subcommand.
type VagrantCreate struct {
	QueryString    string
	Username       string
	KitePrivateKey string
	KitePublicKey  string
	KontrolURL     string
	RegisterURL    string
	KlientURL      string

	req  *vagrantapi.Create
	data *puser.Value
}

// NewVagrantCreate gives new VagrantCreate value.
func NewVagrantCreate() *VagrantCreate {
	return &VagrantCreate{
		req:  &vagrantapi.Create{},
		data: &puser.Value{},
	}
}

// Valid implements the kloud.Validator interface.
func (v *VagrantCreate) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	if v.req.FilePath == "" {
		return errors.New("empty value for -path flag")
	}
	if v.Username == "" {
		return errors.New("empty value for -username flag")
	}
	if v.KitePrivateKey == "" && defaultPrivateKey == "" {
		return errors.New("empty value for -kite-pem flag")
	}
	if v.KitePublicKey == "" && defaultPublicKey == "" {
		return errors.New("empty value for -kite-pub flag")
	}
	if v.KontrolURL == "" {
		return errors.New("empty value for -kontrol-url flag")
	}
	if v.KlientURL == "" {
		return errors.New("empty value for -klient-url flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *VagrantCreate) Name() string {
	return "create"
}

// RegisterFlags sets flags for the command - "vagrant create <flags>".
func (cmd *VagrantCreate) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
	f.StringVar(&cmd.req.FilePath, "path", "", "Path to the directory containing Vagrantfile of the box.")

	// Required, but autodiscovered.
	f.StringVar(&cmd.Username, "username", defaultUsername, "Username for the guest vm.")
	f.StringVar(&cmd.KitePrivateKey, "kite-pem", "", "Private key for generating kite keys.")
	f.StringVar(&cmd.KitePublicKey, "kite-pub", "", "Public key for generating kite keys.")
	f.StringVar(&cmd.KontrolURL, "kontrol-url", defaultKontrolURL(), "Kontrol URL.")
	f.StringVar(&cmd.RegisterURL, "register-url", defaultRegisterURL, "Register URL for the guest klient.")
	f.StringVar(&cmd.KlientURL, "klient-url", defaultKlientURL, "Latest Klient deb package URL.")

	// Optional.
	f.StringVar(&cmd.req.Hostname, "hostname", "", "Hostname of the guest.")
	f.StringVar(&cmd.req.Box, "box", "", "Box type of the guest.")
	f.StringVar(&cmd.req.CustomScript, "script", "", "Custom script to be executed during provisioning.")
	f.IntVar(&cmd.req.Memory, "memory", 2048, "RAM in MiB of the guest vm.")
	f.IntVar(&cmd.req.Cpus, "cpus", 2, "CPU cores of the guest vm.")
}

// Run executes the "vagrant create" subcommand.
func (cmd *VagrantCreate) Run(ctx context.Context) error {
	err := cmd.Valid()
	if err != nil {
		return err
	}

	vapi := vapiFromContext(ctx)

	cmd.req.ProvisionData, err = cmd.provisionData(vapi.Log)
	if err != nil {
		return err
	}

	created, err := vapi.Create(cmd.QueryString, cmd.req)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(created)
}

// provisionData creates the base64-json-encoded userdata.Value to be sent
// altogether with create request.
func (cmd *VagrantCreate) provisionData(log logging.Logger) (string, error) {
	kiteID := uuid.NewV4().String()

	keycreator := &keycreator.Key{
		KontrolURL:        cmd.KontrolURL,
		KontrolPrivateKey: defaultPrivateKey,
		KontrolPublicKey:  defaultPublicKey,
	}

	kiteKey, err := keycreator.Create(cmd.Username, kiteID)
	if err != nil {
		return "", err
	}

	data := &puser.Value{
		Username:        cmd.Username,
		Groups:          []string{"sudo"},
		Hostname:        cmd.Username,
		KiteKey:         kiteKey,
		LatestKlientURL: cmd.KlientURL,
		RegisterURL:     cmd.RegisterURL,
		KontrolURL:      cmd.KontrolURL,
	}

	log.Debug("provision data: %+v", data)

	p, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return base64.StdEncoding.EncodeToString(p), nil
}

/// VAGRANT LIST

// VagrantList provides an implementation for "vagrant list" subcommand.
type VagrantList struct {
	QueryString string
}

// NewVagrantList gives new VagrantList value.
func NewVagrantList() *VagrantList {
	return &VagrantList{}
}

func (v *VagrantList) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *VagrantList) Name() string {
	return "list"
}

// RegisterFlags sets flags for the command - "vagrant list <flags>".
func (cmd *VagrantList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
}

// Run executes the "vagrant list" subcommand.
func (cmd *VagrantList) Run(ctx context.Context) error {
	vapi := vapiFromContext(ctx)

	list, err := vapi.List(cmd.QueryString)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(list)
}

/// VAGRANT VERSION

// VagrantVersion provides an implementation for "vagrant version" subcommand.
type VagrantVersion struct {
	QueryString string
}

// NewVagrantVersion gives new VagrantVersion value.
func NewVagrantVersion() *VagrantVersion {
	return &VagrantVersion{}
}

// Valid implements the kloud.Validator interface.
func (v *VagrantVersion) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *VagrantVersion) Name() string {
	return "version"
}

// RegisterFlags sets flags for the command - "vagrant version <flags>".
func (cmd *VagrantVersion) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
}

// Run executes the "vagrant version" subcommand.
func (cmd *VagrantVersion) Run(ctx context.Context) error {
	vapi := vapiFromContext(ctx)

	version, err := vapi.Version(cmd.QueryString)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(version)
}

/// VAGRANT STATUS

// VagrantCreate provides an implementation for "vagrant status" subcommand.
type VagrantStatus struct {
	QueryString string
	BoxPath     string
}

// NewVagrantStatus gives new VagrantStatus value.
func NewVagrantStatus() *VagrantStatus {
	return &VagrantStatus{}
}

// Valid implements the kloud.Validator interface.
func (v *VagrantStatus) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	if v.BoxPath == "" {
		return errors.New("empty value for -path flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *VagrantStatus) Name() string {
	return "status"
}

// RegisterFlags sets flags for the command - "vagrant status <flags>".
func (cmd *VagrantStatus) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
	f.StringVar(&cmd.BoxPath, "path", "", "Path to the directory containing Vagrantfile of the box.")
}

// Run executes the "vagrant status" subcommand.
func (cmd *VagrantStatus) Run(ctx context.Context) error {
	vapi := vapiFromContext(ctx)

	status, err := vapi.Status(cmd.QueryString, cmd.BoxPath)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(status)
}

/// VAGRANT CMD

// Vagrant provides generic implementation for simple commands - up, halt, destroy.
type VagrantCmd struct {
	QueryString string
	BoxPath     string

	command string
}

// NewVagrantCmd gives new VagrantCmd value.
func NewVagrantCmd(command string) *VagrantCmd {
	return &VagrantCmd{
		command: command,
	}
}

// Valid implements the kloud.Validator interface.
func (v *VagrantCmd) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	if v.BoxPath == "" {
		return errors.New("empty value for -path flag")
	}
	return nil
}

// Name gives the name of the command, implements the res.Command interface.
func (cmd *VagrantCmd) Name() string {
	return cmd.command
}

// RegisterFlags sets flags for the command - "vagrant up|halt|destroy <flags>".
func (cmd *VagrantCmd) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
	f.StringVar(&cmd.BoxPath, "path", "", "Path to the directory containing Vagrantfile of the box.")
}

// Run executes the "vagrant up|halt|destroy" subcommand.
func (cmd *VagrantCmd) Run(ctx context.Context) error {
	vapi := vapiFromContext(ctx)

	var err error
	switch cmd.command {
	case "up":
		err = vapi.Up(cmd.QueryString, cmd.BoxPath)
	case "halt":
		err = vapi.Halt(cmd.QueryString, cmd.BoxPath)
	case "destroy":
		err = vapi.Destroy(cmd.QueryString, cmd.BoxPath)
	default:
		return errors.New("unknown command: " + cmd.command)
	}

	return err
}

var vapiKey struct {
	byte `key:"vapi"`
}

func vapiFromContext(ctx context.Context) *vagrantapi.Klient {
	return ctx.Value(vapiKey).(*vagrantapi.Klient)
}
