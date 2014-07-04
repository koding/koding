package lxc

import "github.com/lxc/go-lxc"

type ContainerFunc func(*Container) error

type LXC struct {
	Name       string
	ConfigPath string
}

// New returns a new LXC instance with the given name. The default config path
// is /var/lib/lxc
func New(name string) *LXC {
	return NewWithPath(name, lxc.DefaultConfigPath())
}

// NewWithPath returns a new LXC instance with the given name and config path.
func NewWithPath(name, configPath string) *LXC {
	return &LXC{
		Name:       name,
		ConfigPath: configPath,
	}
}

func (l *LXC) runInContainerContext(fn ContainerFunc) error {
	c, err := lxc.NewContainer(l.Name, l.ConfigPath)
	if err != nil {
		return err
	}
	defer lxc.PutContainer(c)

	return fn(c)
}
