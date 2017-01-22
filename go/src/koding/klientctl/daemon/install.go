package daemon

import (
	"errors"
	"fmt"
	"net/url"
	"os"
	"runtime"
	"strconv"
	"strings"

	conf "koding/kites/config"
	"koding/kites/config/configstore"
	"koding/klient/tunnel/tlsproxy"
	"koding/klient/uploader"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/auth"
	"koding/tools/util"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/logging"
)

var ErrSkipInstall = errors.New("skip installation step")

type InstallResult struct {
	Skipped bool   `json:"skipped"`
	Name    string `json:"name,omitempty"`
	Version string `json:"version,omitempty"`
}

type InstallStep struct {
	Name        string
	Install     func(*Client, *Opts) (string, error)
	Uninstall   func(*Client, *Opts) error
	RunOnUpdate bool
}

type Opts struct {
	Force   bool
	Token   string
	Prefix  string
	Baseurl string
	Team    string
	Skip    []string
}

func (c *Client) Install(opts *Opts) error {
	c.init()

	if opts.Prefix != "" {
		c.d.setPrefix(opts.Prefix)
	}

	start := len(c.d.Installation)

	switch start {
	case 0:
		fmt.Fprintln(c.stderr(), "Performing fresh installation ...")
	case len(script):
		return errors.New(`Already installed. To reinstall, run "sudo kd daemon uninstall" first.`)
	default:
		fmt.Fprintf(c.stderr(), "Resuming installation at %q step ...\n", script[start].Name)
	}

	skip := make(map[string]struct{}, len(opts.Skip))
	for _, s := range opts.Skip {
		skip[strings.ToLower(s)] = struct{}{}
	}

	var err, merr error
	for _, step := range c.script()[start:] {
		fmt.Fprintf(c.stderr(), "Installing %q ...\n", step.Name)

		result := InstallResult{
			Name: step.Name,
		}

		if _, ok := skip[strings.ToLower(step.Name)]; ok {
			result.Skipped = true
		} else {
			result.Version, err = step.Install(c, opts)
			switch err {
			case ErrSkipInstall:
				result.Skipped = true
			case nil:
			default:
				if !opts.Force {
					return fmt.Errorf("error installing %q: %s", step.Name, err)
				}

				merr = multierror.Append(merr, err)
			}
		}

		c.d.Installation = append(c.d.Installation, result)
	}

	// TODO(rjeczalik): ensure client is running

	return merr
}

func (c *Client) Uninstall(opts *Opts) error {
	c.init()

	start := min(len(c.d.Installation), len(c.script()))

	switch start {
	case 0:
		return errors.New(`Already uninstalled. To install again, run "sudo kd daemon install".`)
	case len(script):
		fmt.Fprintln(c.stderr(), "Performing full uninstallation ...")
	default:
		fmt.Fprintf(c.stderr(), "Performing partial uninstallation at %q step ...\n", c.script()[start].Name)
	}

	var merr error
	for i := start; i >= 0; i-- {
		step := c.script()[i]

		fmt.Fprintf(c.stderr(), "Uninstalling %q ...\n", step.Name)

		if step.Uninstall != nil {
			switch err := step.Uninstall(c, opts); err {
			case nil, ErrSkipInstall:
			default:
				if !opts.Force {
					return fmt.Errorf("error uninstalling %q: %s", step.Name, err)
				}

				merr = multierror.Append(merr, err)
			}
		}

		c.d.Installation = c.d.Installation[:i]
	}

	return merr
}

func (c *Client) Update(opts *Opts) error {
	c.init()

	if len(c.d.Installation) != len(c.script()) {
		return errors.New(`KD is not yet installed. Please run "sudo kd daemon install".`)
	}

	var merr error
	for i, step := range c.script() {
		if !step.RunOnUpdate || c.Install == nil {
			continue
		}

		switch version, err := step.Install(c, opts); err {
		case nil:
			c.d.Installation[i].Version = version
		case ErrSkipInstall:
		default:
			if !opts.Force {
				return fmt.Errorf("error uninstalling %q: %s", step.Name, err)
			}

			merr = multierror.Append(merr, err)
		}
	}

	// TODO(rjeczalik): ensure klient is running

	return merr
}

var script = []InstallStep{{
	Name: "log files",
	Install: func(c *Client, _ *Opts) (string, error) {
		uid, gid, err := util.UserIDs(conf.CurrentUser.User)
		if err != nil {
			return "", err
		}

		path := c.d.LogFiles["kd"][runtime.GOOS]

		f, err := os.OpenFile(path, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0666)
		if err != nil {
			return "", err
		}

		ctlcli.CloseOnExit(f)

		if err := f.Chown(uid, gid); err != nil {
			return "", err
		}

		c.log().SetHandler(logging.NewWriterHandler(f))
		fmt.Fprintf(c.stderr(), "Created log file: %s\n", path)

		if f, err := os.Create(c.d.LogFiles["klient"][runtime.GOOS]); err == nil {
			err = nonil(f.Chown(uid, gid), f.Close())
		}

		return "", err
	},
	Uninstall: func(c *Client, _ *Opts) (err error) {
		for _, file := range c.d.LogFiles {
			err = nonil(err, os.Remove(file[runtime.GOOS]))
		}
		return err
	},
}, {
	Name: "directory structure",
	Install: func(c *Client, _ *Opts) (string, error) {
		return "", os.MkdirAll(c.d.KlientHome, 0755)
	},
}, (map[string]InstallStep{
	"darwin": {
		Name: "osxfuse",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
	"linux": {
		Name: "osxfuse",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
})[runtime.GOOS], (map[string]InstallStep{
	"darwin": {
		Name: "Vagrant",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
	"linux": {
		Name: "Vagrant",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
})[runtime.GOOS], (map[string]InstallStep{
	"darwin": {
		Name: "VirtualBox",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
	"linux": {
		Name: "VirtualBox",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
		Uninstall: func(c *Client, _ *Opts) error {
			return nil
		},
	},
})[runtime.GOOS], {
	Name: "KD Daemon",
	Install: func(c *Client, _ *Opts) (string, error) {
		var version, newVersion int

		if n, err := parseVersion(c.d.Files["klient"]); err == nil {
			version = n
		}

		if err := curl(c.klientLatest(), "%d", &newVersion); err != nil {
			return "", err
		}

		if version != 0 && newVersion <= version {
			return strconv.Itoa(version), nil
		}

		svc, err := c.d.service()
		if err != nil {
			return "", err
		}

		// Best-effort attempt at stopping the running klient, if any.
		_ = svc.Stop()

		if err := wget(c.klient(newVersion), c.d.Files["klient"]); err != nil {
			return "", err
		}

		if err := c.d.helper().Create(); err != nil {
			return "", err
		}

		// Best-effort attempt at uninstalling klient service, if any.
		_ = svc.Uninstall()

		if err := svc.Install(); err != nil {
			return "", err
		}

		// Best-effort attempts at fixinig permissions and ownership, ignore any errors.
		_ = configstore.FixOwner()
		_ = uploader.FixPerms()
		_ = tlsproxy.Init()

		if err := svc.Start(); err != nil {
			return "", err
		}

		if n, err := parseVersion(c.d.Files["klient"]); err == nil {
			version = n
		}

		return strconv.Itoa(version), nil
	},
	Uninstall: func(c *Client, _ *Opts) error {
		svc, err := c.d.service()
		if err != nil {
			return err
		}

		_ = svc.Stop() // ignore failue, klient may be already stopped

		if err = svc.Uninstall(); err != nil {
			return err
		}

		return nonil(os.Remove(c.d.Files["klient.sh"]), os.Remove(c.d.Files["klient"]))
	},
	RunOnUpdate: true,
}, {
	Name: "KD",
	Install: func(c *Client, _ *Opts) (string, error) {
		var newVersion int

		if err := curl(c.kdLatest(), "%d", &newVersion); err != nil {
			return "", err
		}

		if newVersion <= config.VersionNum() {
			return config.Version, nil
		}

		if err := wget(c.kd(newVersion), c.d.Files["kd"]); err != nil {
			return "", err
		}

		return strconv.Itoa(newVersion), nil
	},
	Uninstall: func(c *Client, _ *Opts) error {
		return os.Remove(c.d.Files["kd"])
	},
	RunOnUpdate: true,
}, {
	Name: "Koding account",
	Install: func(c *Client, opts *Opts) (string, error) {
		base, err := url.Parse(opts.Baseurl)
		if err != nil {
			return "", err
		}

		f := auth.NewFacade(&auth.FacadeOpts{
			Base: base,
			Log:  c.log(),
		})

		resp, err := f.Login(&auth.LoginOptions{
			Team:  opts.Team,
			Token: opts.Token,
		})

		if err != nil {
			return "", err
		}

		_ = resp

		return "", nil
	},
}, {
	Name: "Start KD Deamon",
	Install: func(c *Client, _ *Opts) (string, error) {
		svc, err := c.d.service()
		if err != nil {
			return "", err
		}

		return "", svc.Start()
	},
	RunOnUpdate: true,
}}
