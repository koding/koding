package command

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/url"
	"os"
	"strings"
	"text/template"

	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/utils/res"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/mitchellh/cli"
	"github.com/satori/go.uuid"
	"golang.org/x/net/context"
)

type Kontrol struct {
	*res.Resource
}

type Kite struct {
	Name        string `json:"name,omitempty"`
	Username    string `json:"username,omitempty"`
	ID          string `json:"id,omitempty"`
	Environment string `json:"environment,omitempty"`
	Region      string `json:"region,omitempty"`
	Version     string `json:"version,omitempty"`
	Hostname    string `json:"hostname,omitempty"`
	Reconnect   bool   `json:"reconnect,omitempty"`
	URL         string `json:"url,omitempty"`
	Concurrent  bool   `json:"concurrent,omitempty"`
	KontrolURL  string `json:"kontrolURL,omitempty"`
	// KontrolKey  string `json:"kontrolKey,omitempty"`
	KontrolUser string `json:"kontrolUser,omitempty"`
	AuthType    string `json:"authType,omitempty"`
	// AuthKey     string `json:"authKey,omitempty"`
}

func newKite(k *kite.Client) *Kite {
	return &Kite{
		Name:        k.Name,
		Username:    k.Username,
		ID:          k.ID,
		Environment: k.Environment,
		Region:      k.Region,
		Version:     k.Version,
		Hostname:    k.Hostname,
		URL:         k.URL,
		Reconnect:   k.Reconnect,
		Concurrent:  k.Concurrent,
		KontrolURL:  k.LocalKite.Config.KontrolURL,
		// KontrolKey:  k.LocalKite.Config.KontrolKey,
		KontrolUser: k.LocalKite.Config.KontrolUser,
		AuthType:    k.Auth.Type,
		// AuthKey:     k.Auth.Key,
	}
}

var funcs = map[string]interface{}{
	"host": func(s string) (string, error) {
		u, err := url.Parse(s)
		if err != nil {
			return "", err
		}
		host, _, err := net.SplitHostPort(u.Host)
		if err != nil {
			return u.Host, nil
		}
		return host, nil
	},
	"port": func(s string) (string, error) {
		u, err := url.Parse(s)
		if err != nil {
			return "", err
		}
		_, port, err := net.SplitHostPort(u.Host)
		if err != nil {
			return "80", nil
		}
		return port, nil
	},
	"json": func(v interface{}) (string, error) {
		p, err := json.MarshalIndent(v, "", "\t")
		if err != nil {
			return "", err
		}
		return string(p), nil
	},
}

func NewKontrol() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("kontrol", "Kontrol client.")
		f.action = &Kontrol{
			Resource: &res.Resource{
				Name:        "kontrol",
				Description: "Kontrol client.",
				Commands: map[string]res.Command{
					"list": NewKontrolList(),
					"key":  NewKontrolKey(),
				},
			},
		}
		return f, nil
	}
}

func (ktrl *Kontrol) Action(args []string) error {
	k, err := kloudClient()
	if err != nil {
		return err
	}
	ctx := context.WithValue(context.Background(), kiteKey, k)
	ktrl.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return ktrl.Resource.Main(args)
}

type KontrolList struct {
	req      *protocol.KontrolQuery
	template string
}

func NewKontrolList() *KontrolList {
	return &KontrolList{
		req: &protocol.KontrolQuery{},
	}
}

func (cmd *KontrolList) Name() string {
	return "list"
}

func (cmd *KontrolList) Valid() error {
	if *cmd.req == (protocol.KontrolQuery{}) {
		return errors.New("all fields are empty")
	}
	return nil
}

func (cmd *KontrolList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.req.Username, "user", "", "Sets username for kontrol query.")
	f.StringVar(&cmd.req.Environment, "env", "development", "Sets environment for kontrol query.")
	f.StringVar(&cmd.req.Name, "name", "", "Sets kite name for kontrol query.")
	f.StringVar(&cmd.req.Version, "version", "", "Sets kite version for kontrol query.")
	f.StringVar(&cmd.req.Region, "region", "", "Sets region for kontrol query.")
	f.StringVar(&cmd.req.Hostname, "host", "", "Sets hostname for kontrol query.")
	f.StringVar(&cmd.req.ID, "id", "", "Sets kite ID for kontrol query.")
	f.StringVar(&cmd.template, "t", "", "Template to apply on kite list.")
}

func (cmd *KontrolList) Run(ctx context.Context) error {
	k := kiteFromContext(ctx)

	clients, err := k.LocalKite.GetKites(cmd.req)
	if err != nil {
		return err
	}

	kites := make([]*Kite, len(clients))
	for i, client := range clients {
		kites[i] = newKite(client)
	}

	if cmd.template == "" {
		return json.NewEncoder(os.Stdout).Encode(kites)
	}

	tmpl, err := template.New("").Funcs(funcs).Parse(cmd.template)
	if err != nil {
		return err
	}

	return tmpl.Execute(os.Stdout, kites)
}

type KontrolKey struct {
	username   string
	kontrolURL string
	output     string
}

func NewKontrolKey() *KontrolKey {
	return &KontrolKey{}
}

func (*KontrolKey) Name() string {
	return "key"
}

func (cmd *KontrolKey) Valid() error {
	if cmd.username == "" {
		return errors.New("empty value provided for -username flag")
	}
	if cmd.kontrolURL == "" {
		return errors.New("empty value provided for -kontrol-url flag")
	}
	return nil
}

func (cmd *KontrolKey) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.username, "u", defaultUsername, "Username for the key.")
	f.StringVar(&cmd.kontrolURL, "kontrol-url", fmt.Sprintf("http://koding-%s.ngrok.com/kontrol/kite", defaultUsername), "Kontrol URL for the key.")
	f.StringVar(&cmd.output, "o", "-", "Output file to write the key to.")
}

func (cmd *KontrolKey) Run(ctx context.Context) error {
	kiteID := uuid.NewV4().String()

	keycreator := &keycreator.Key{
		KontrolURL:        cmd.kontrolURL,
		KontrolPrivateKey: defaultPrivateKey,
		KontrolPublicKey:  defaultPublicKey,
	}

	kiteKey, err := keycreator.Create(cmd.username, kiteID)
	if err != nil {
		return err
	}

	f := os.Stdout
	if cmd.output != "-" {
		f, err = os.Create(cmd.output)
		if err != nil {
			return err
		}
	}

	_, err = io.Copy(f, strings.NewReader(kiteKey))
	return nonil(err, f.Sync(), f.Close())
}
