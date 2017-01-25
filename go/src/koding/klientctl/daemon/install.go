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

	if opts.Baseurl == "" {
		return errors.New("invalid empty -baseurl value")
	}

	base, err := url.Parse(opts.Baseurl)
	if err != nil {
		return err
	}

	if opts.Prefix != "" {
		c.d.setPrefix(opts.Prefix)
	}

	start := len(c.d.Installation)

	switch start {
	case 0:
		fmt.Fprintln(os.Stderr, "Performing fresh installation ...")
	case len(script):
		return errors.New(`Already installed. To reinstall, run "sudo kd daemon uninstall" first.`)
	default:
		fmt.Fprintf(os.Stderr, "Resuming installation at %q step ...\n", script[start].Name)
	}

	c.d.Base = &conf.URL{
		URL: base,
	}

	skip := make(map[string]struct{}, len(opts.Skip))
	for _, s := range opts.Skip {
		skip[strings.ToLower(s)] = struct{}{}
	}

	var merr error
	for _, step := range c.script()[start:] {
		fmt.Fprintf(os.Stderr, "Installing %q ...\n", step.Name)

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

	if err = c.Ping(); err != nil {
		if merr == nil {
			return err
		}

		merr = multierror.Append(merr, err)
	}

	return merr
}

func (c *Client) Uninstall(opts *Opts) error {
	c.init()

	start := min(len(c.d.Installation), len(c.script())) - 1

	switch start {
	case -1:
		return errors.New(`Already uninstalled. To install again, run "sudo kd daemon install".`)
	case len(script) - 1:
		fmt.Fprintln(os.Stderr, "Performing full uninstallation ...")
	default:
		fmt.Fprintf(os.Stderr, "Performing partial uninstallation at %q step ...\n", c.script()[start].Name)
	}

	var merr error
	for i := start; i >= 0; i-- {
		step := c.script()[i]

		fmt.Fprintf(os.Stderr, "Uninstalling %q ...\n", step.Name)

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

	if err := c.Ping(); err != nil {
		if merr == nil {
			return err
		}

		merr = multierror.Append(merr, err)
	}

	return merr
}

var script = []InstallStep{{
	Name: "log files",
	Install: func(c *Client, _ *Opts) (string, error) {
		uid, gid, err := util.UserIDs(conf.CurrentUser.User)
		if err != nil {
			return "", err
		}

		kd := c.d.LogFiles["kd"][runtime.GOOS]
		klient := c.d.LogFiles["klient"][runtime.GOOS]

		f, err := os.OpenFile(kd, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0666)
		if err != nil {
			return "", err
		}

		ctlcli.CloseOnExit(f)

		if err := f.Chown(uid, gid); err != nil {
			return "", err
		}

		c.log().SetHandler(logging.NewWriterHandler(f))
		fmt.Fprintf(os.Stderr, "Created log file: %s\n", kd)

		if f, err := os.Create(klient); err == nil {
			err = nonil(f.Chown(uid, gid), f.Close())
			fmt.Fprintf(os.Stderr, "Created log file: %s\n", klient)
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
		return "", nonil(os.MkdirAll(c.d.KlientHome, 0755), os.MkdirAll(c.d.KodingHome, 0755))
	},
	Uninstall: func(c *Client, _ *Opts) error {
		return os.RemoveAll(c.d.KodingHome)
	},
}, (map[string]InstallStep{
	"darwin": {
		Name: "osxfuse",
		Install: func(c *Client, _ *Opts) (string, error) {
			const volume = "/Volumes/FUSE for macOS"
			const pkg = volume + "/Extras/FUSE for macOS 3.5.2.pkg"

			if _, err := os.Stat("/Library/Filesystems/osxfuse.fs"); err == nil {
				return "", ErrSkipInstall
			}

			dmg := c.d.Osxfuse

			if err := dmgInstall(dmg.String(), volume, pkg); err != nil {
				return "", err
			}

			return dmg.Version, nil
		},
	},
	"linux": {
		Name: "osxfuse",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", ErrSkipInstall
		},
	},
})[runtime.GOOS], (map[string]InstallStep{
	"darwin": {
		Name: "VirtualBox",
		Install: func(c *Client, _ *Opts) (string, error) {
			const volume = "/Volumes/VirtualBox"
			const pkg = volume + "/VirtualBox.pkg"

			if hasVirtualBox() {
				return "", ErrSkipInstall
			}

			dmg := c.d.Virtualbox[runtime.GOOS]

			if err := dmgInstall(dmg.String(), volume, pkg); err != nil {
				return "", err
			}

			return dmg.Version, nil
		},
	},
	"linux": {
		Name: "VirtualBox",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
	},
})[runtime.GOOS], (map[string]InstallStep{
	"darwin": {
		Name: "Vagrant",
		Install: func(c *Client, _ *Opts) (string, error) {
			const volume = "/Volumes/Vagrant"
			const pkg = volume + "/Vagrant.pkg"

			if hasVagrant() {
				return "", ErrSkipInstall
			}

			dmg := c.d.Vagrant[runtime.GOOS]

			if err := dmgInstall(dmg.String(), volume, pkg); err != nil {
				return "", err
			}

			// Best-effort workaround for Vagrant 1.8.7, which fails to "box add".
			_ = os.Remove("/opt/vagrant/embedded/bin/curl")

			return dmg.Version, nil
		},
	},
	"linux": {
		Name: "Vagrant",
		Install: func(c *Client, _ *Opts) (string, error) {
			return "", nil
		},
	},
})[runtime.GOOS], {
	Name: "Koding account",
	Install: func(c *Client, opts *Opts) (string, error) {
		f, err := c.newFacade()
		if err != nil {
			return "", err
		}

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
		_ = svc.Uninstall()

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

		kd := c.d.Files["kd"]

		if _, err := os.Stat(kd); err == nil && newVersion <= config.VersionNum() {
			return config.Version, nil
		}

		if err := wget(c.kd(newVersion), kd); err != nil {
			return "", err
		}

		return strconv.Itoa(newVersion), nil
	},
	RunOnUpdate: true,
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

func hasVirtualBox() bool {
	const s = "Oracle VM VirtualBox Headless Interface"

	p, err := cmd("VBoxHeadless", "-h").CombinedOutput()
	if err != nil {
		return false
	}

	return strings.Contains(string(p), s)
}

func hasVagrant() bool {
	const s = "Installed Version:"

	cmd := cmd("vagrant", "version")
	cmd.Env = append(os.Environ(), "VAGRANT_CHECKPOINT_DISABLE=1")

	p, err := cmd.CombinedOutput()
	if err != nil {
		return false
	}

	return strings.Contains(string(p), s)
}
