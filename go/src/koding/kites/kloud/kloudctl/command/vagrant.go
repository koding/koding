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
	"os"
	"os/exec"
	"os/user"
	"path/filepath"

	"koding/kites/common"
	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/keycreator"
	puser "koding/kites/kloud/scripts/provisionklient/userdata"
	"koding/kites/kloud/utils/res"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/cli"
	"github.com/satori/go.uuid"
	"golang.org/x/net/context"
)

var (
	defaultHost        = os.Getenv("KLOUDCTL_VAGRANT_HOST")
	defaultUsername    string
	defaultPrivateKey  string
	defaultPublicKey   string
	defaultKontrolURL  string
	defaultRegisterURL string // tunnel for 127.0.0.1:56790
	defaultKlientURL   = "https://koding-klient.s3.amazonaws.com/development/latest/klient_0.1.135_development_amd64.deb"
)

func init() {
	u, err := user.Current()
	if err != nil {
		log.Println("unable to get current user:", err)
		return
	}

	defaultUsername = u.Username
	defaultKontrolURL = fmt.Sprintf("http://koding-%s.ngrok.com/kontrol/kite", u.Username)
	defaultRegisterURL = fmt.Sprintf("http://guest-klient-%s.ngrok.com/kite", u.Username)

	p, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		log.Println("unable to get git top dir:", err)
		return
	}

	top := string(bytes.TrimSpace(p))

	p, err = ioutil.ReadFile(filepath.Join(top, "certs", "test_kontrol_rsa_private.pem"))
	if err != nil {
		log.Println("unable to read private key:", err)
		return
	}

	defaultPrivateKey = string(p)

	p, err = ioutil.ReadFile(filepath.Join(top, "certs", "test_kontrol_rsa_public.pem"))
	if err != nil {
		log.Println("unable to read private key:", err)
		return
	}

	defaultPublicKey = string(p)
}

type Vagrant struct {
	*res.Resource
}

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

func (v *Vagrant) Action(args []string, k *kite.Client) error {
	vapi := &vagrantapi.Klient{
		Kite: k.LocalKite,
		Log:  common.NewLogger("vagrant", flagDebug),
	}

	ctx := context.Background()
	ctx = context.WithValue(ctx, vapiKey, vapi)
	v.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return v.Resource.Main(args)
}

/// VAGRANT CREATE

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

func NewVagrantCreate() *VagrantCreate {
	return &VagrantCreate{
		req:  &vagrantapi.Create{},
		data: &puser.Value{},
	}
}

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

func (cmd *VagrantCreate) Name() string {
	return "create"
}

func (cmd *VagrantCreate) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
	f.StringVar(&cmd.req.FilePath, "path", "", "Path to the directory containing Vagrantfile of the box.")

	// Required, but autodiscovered.
	f.StringVar(&cmd.Username, "username", defaultUsername, "Username for the guest vm.")
	f.StringVar(&cmd.KitePrivateKey, "kite-pem", "", "Private key for generating kite keys.")
	f.StringVar(&cmd.KitePublicKey, "kite-pub", "", "Public key for generating kite keys.")
	f.StringVar(&cmd.KontrolURL, "kontrol-url", defaultKontrolURL, "Kontrol URL.")
	f.StringVar(&cmd.RegisterURL, "register-url", defaultRegisterURL, "Register URL for the guest klient.")
	f.StringVar(&cmd.KlientURL, "klient-url", defaultKlientURL, "Latest Klient deb package URL.")

	// Optional.
	f.StringVar(&cmd.req.Hostname, "hostname", "", "Hostname of the guest.")
	f.StringVar(&cmd.req.Box, "box", "", "Box type of the guest.")
	f.StringVar(&cmd.req.CustomScript, "script", "", "Custom script to be executed during provisioning.")
	f.IntVar(&cmd.req.Memory, "memory", 2048, "RAM in MiB of the guest vm.")
	f.IntVar(&cmd.req.Cpus, "cpus", 2, "CPU cores of the guest vm.")
}

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

type VagrantList struct {
	QueryString string
}

func NewVagrantList() *VagrantList {
	return &VagrantList{}
}

func (v *VagrantList) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	return nil
}

func (cmd *VagrantList) Name() string {
	return "list"
}

func (cmd *VagrantList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
}

func (cmd *VagrantList) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}

	vapi := vapiFromContext(ctx)

	list, err := vapi.List(cmd.QueryString)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(list)
}

/// VAGRANT VERSION

type VagrantVersion struct {
	QueryString string
}

func NewVagrantVersion() *VagrantVersion {
	return &VagrantVersion{}
}

func (v *VagrantVersion) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	return nil
}

func (cmd *VagrantVersion) Name() string {
	return "version"
}

func (cmd *VagrantVersion) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
}

func (cmd *VagrantVersion) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}

	vapi := vapiFromContext(ctx)

	version, err := vapi.Version(cmd.QueryString)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(version)
}

/// VAGRANT STATUS

type VagrantStatus struct {
	QueryString string
	BoxPath     string
}

func NewVagrantStatus() *VagrantStatus {
	return &VagrantStatus{}
}

func (v *VagrantStatus) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	if v.BoxPath == "" {
		return errors.New("empty value for -path flag")
	}
	return nil
}

func (cmd *VagrantStatus) Name() string {
	return "status"
}

func (cmd *VagrantStatus) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
	f.StringVar(&cmd.BoxPath, "path", "", "Path to the directory containing Vagrantfile of the box.")
}

func (cmd *VagrantStatus) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}
	vapi := vapiFromContext(ctx)

	status, err := vapi.Status(cmd.QueryString, cmd.BoxPath)
	if err != nil {
		return err
	}

	return json.NewEncoder(os.Stdout).Encode(status)
}

/// VAGRANT CMD

type VagrantCmd struct {
	QueryString string
	BoxPath     string

	command string
}

func NewVagrantCmd(command string) *VagrantCmd {
	return &VagrantCmd{
		command: command,
	}
}

func (v *VagrantCmd) Valid() error {
	if v.QueryString == "" {
		return errors.New("empty value for -host flag")
	}
	if v.BoxPath == "" {
		return errors.New("empty value for -path flag")
	}
	return nil
}

func (cmd *VagrantCmd) Name() string {
	return cmd.command
}

func (cmd *VagrantCmd) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.QueryString, "host", defaultHost, "QueryString for the Vagramt klient on host.")
	f.StringVar(&cmd.BoxPath, "path", "", "Path to the directory containing Vagrantfile of the box.")
}

func (cmd *VagrantCmd) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}

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
