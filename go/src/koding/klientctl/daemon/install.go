package daemon

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	conf "koding/kites/config"
)

type Details struct {
	Username     string          `json:"username"`
	KlientHome   string          `json:"klientHome"`
	Installation []InstallResult `json:"status,omitempty"`
}

func newDetails() *Details {
	return &Details{
		Username:   conf.CurrentUser.Username,
		KlientHome: filepath.FromSlash("/opt/kite/klient"),
	}
}

var ErrSkipInstall = errors.New("skip installation step")

type InstallResult struct {
	Skipped bool   `json:"skipped"`
	Name    string `json:"name,omitempty"`
	Version string `json:"version,omitempty"`
}

type InstallStep struct {
	Name        string
	Install     func(*Client, *InstallOpts) (string, error)
	Uninstall   func(*Client, *UninstallOpts) error
	RunOnUpdate bool
}

type InstallOpts struct {
	Force bool
	Token string
	Skip  []string
}

func (c *Client) Install(opts *InstallOpts) error {
	c.init()

	start := len(c.details.Installation)

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

	var err error
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
				return fmt.Errorf("error installing %q: %s", step.Name, err)
			}
		}

		c.details.Installation = append(c.details.Installation, result)
	}

	// TODO(rjeczalik): ensure client is running

	return nil
}

type UninstallOpts struct {
	Force bool
}

func (c *Client) Uninstall(opts *UninstallOpts) error {
	c.init()

	start := min(len(c.details.Installation), len(c.script()))

	switch start {
	case 0:
		return errors.New(`Already uninstalled. To install again, run "sudo kd daemon install".`)
	case len(script):
		fmt.Fprintln(c.stderr(), "Performing full uninstallation ...")
	default:
		fmt.Fprintf(c.stderr(), "Performing partial uninstallation at %q step ...\n", c.script()[start].Name)
	}

	for i := start; i >= 0; i-- {
		step := c.script()[i]

		fmt.Fprintf(c.stderr(), "Uninstalling %q ...\n", step.Name)

		if step.Uninstall != nil {
			switch err := step.Uninstall(c, opts); err {
			case nil, ErrSkipInstall:
			default:
				return fmt.Errorf("error uninstalling %q: %s", step.Name, err)
			}
		}

		c.details.Installation = c.details.Installation[:i]
	}

	return nil
}

type UpdateOpts struct {
	Force bool
}

func (c *Client) Update(opts *UpdateOpts) error {
	c.init()

	if len(c.details.Installation) != len(c.script()) {
		return errors.New(`KD is not yet installed. Please run "sudo kd daemon install".`)
	}

	installOpts := &InstallOpts{
		Force: opts.Force,
	}

	for i, step := range c.script() {
		if !step.RunOnUpdate || c.Install == nil {
			continue
		}

		switch version, err := step.Install(c, installOpts); err {
		case nil:
			c.details.Installation[i].Version = version
		case ErrSkipInstall:
		default:
			return fmt.Errorf("error uninstalling %q: %s", step.Name, err)
		}
	}

	// TODO(rjeczalik): ensure klient is running

	return nil
}

var script = []InstallStep{{
	Name: "log files",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
}, {
	Name: "directory structure",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
}, {
	Name: "osxfuse",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
	Uninstall: func(c *Client, opts *UninstallOpts) error {
		return nil
	},
}, {
	Name: "Vagrant",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
	Uninstall: func(c *Client, opts *UninstallOpts) error {
		return nil
	},
}, {
	Name: "VirtualBox",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
	Uninstall: func(c *Client, opts *UninstallOpts) error {
		return nil
	},
}, {
	Name: "KD",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
	Uninstall: func(c *Client, opts *UninstallOpts) error {
		return nil
	},
	RunOnUpdate: true,
}, {
	Name: "KD Daemon",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
	Uninstall: func(c *Client, opts *UninstallOpts) error {
		return nil
	},
	RunOnUpdate: true,
}, {
	Name: "Koding account",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
}, {
	Name: "Start KD Deamon",
	Install: func(c *Client, opts *InstallOpts) (string, error) {
		return "", nil
	},
	RunOnUpdate: true,
}}
