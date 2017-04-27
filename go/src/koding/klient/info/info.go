package info

import (
	"runtime"
	"sort"

	"koding/kites/config"
	"koding/klient/proxy"
)

type InfoResponse struct {
	// ProviderName is the name of the machine (vm or otherwise) provider,
	// as identified by the
	ProviderName	string		`json:"providerName"`

	Username        string  	`json:"username"`
	Home            string  	`json:"home"`
	Groups          []string	`json:"groups"`
	OS              string		`json:"os"`
	Arch            string		`json:"arch"`

	// Supports identifies which kite methods that klient currently can
	// respond to. This changes based on what environment klient is running
	// in (i.e. In Kubernetes for example, we don't support fs.* yet)
	Supports		[]string	`json:"supports"`

	// ContainerProxy determines how a klient kite accesses the container(s)
	// it is bound to. This controls proxy logic for specific kite methods
	// in klient, delegating to a 3rd party service for the transport. In the
	// case when we have container based stacks; klient is not in the same
	// context as it's containers(s).
	ContainerProxy	proxy.ProxyType	`json:"containerproxy"`
}

// Info implements the klient.info method, returning klient specific
// information about the machine klient is running within.
//
// See also `kite.info`.
func Info(r *kite.Request) (interface{}, error) {
	providerName, err := CheckProvider()
	if err != nil {
		return InfoResponse{}, err
	}

	prox := proxy.Factory()

	i := &InfoResponse{
		ProviderName: 	providerName.String(),
		Username:     	config.CurrentUser.Username,
		Home:         	config.CurrentUser.HomeDir,
		OS:           	runtime.GOOS,
		Arch:         	runtime.GOARCH,

		Supports:       prox.Methods(),

		ContainerProxy:	prox.Type(),
	}

	for _, group := range config.CurrentUser.Groups {
		i.Groups = append(i.Groups, group.Name)
	}

	sort.Strings(i.Groups)

	return i, nil
}
