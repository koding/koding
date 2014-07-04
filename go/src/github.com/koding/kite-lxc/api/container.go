package api

import (
	"errors"

	"github.com/lxc/go-lxc"
)

type CreateOptions struct {
	Template string
	Distro   string
	Release  string
	Arch     string
	User     bool
	Args     []string
	Backend  lxc.BackendStore
}

func (l *LXC) Create(opts CreateOptions) error {
	nargs := opts.Args
	if opts.Args == nil {
		nargs = []string{}
	}

	fn := func(c *lxc.Container) error {
		if opts.User {
			if opts.Distro == "" {
				return errors.New("create: distro field is required.")
			}

			if opts.Release == "" {
				return errors.New("create: release field is required.")
			}

			if opts.Arch == "" {
				return errors.New("create: arch field is required.")
			}

			return c.CreateAsUser(opts.Distro, opts.Release, opts.Arch, nargs...)
		}

		if opts.Template == "" {
			return errors.New("create: template field is required.")
		}

		if opts.Backend == 0 {
			return c.Create(opts.Template, nargs...)
		}

		return c.CreateUsing(opts.Template, opts.Backend, nargs...)
	}

	return l.runInContainerContext(fn)
}

func (l *LXC) Destroy() error {
	fn := func(c *lxc.Container) error {
		return c.Destroy()
	}

	return l.runInContainerContext(fn)
}
