package info

import (
	"runtime"
	"sort"

	"koding/kites/config"

	"github.com/koding/kite"
)

type info struct {
	// ProviderName is the name of the machine (vm or otherwise) provider,
	// as identified by the
	ProviderName 	string	 `json:"providerName"`

	Username 		string   `json:"username"`
	Home     		string   `json:"home"`
	Groups   		[]string `json:"groups"`
	OS       		string   `json:"os"`
	Arch     		string   `json:"arch"`

	// Proxy tells whether or not this klient will proxy specific
	// API actions to separate machines in order to satisfy the API
	// result. This is the case when we have container based stacks;
	// klient is not in the same "machine" as other stack resources.
	Proxy			string	 `json:"proxy"`
}

// Info implements the klient.info method, returning klient specific
// information about the machine klient is running within.
//
// See also `kite.info`.
func Info(r *kite.Request) (interface{}, error) {
	providerName, err := CheckProvider()
	if err != nil {
		return info{}, err
	}

	i := &info{
		ProviderName: providerName.String(),
		Username:     config.CurrentUser.Username,
		Home:         config.CurrentUser.HomeDir,
		OS:           runtime.GOOS,
		Arch:         runtime.GOARCH,

		// TODO (acbodine): Make this change based on ./klient parameters.
		Proxy: 		  "local",
	}

	for _, group := range config.CurrentUser.Groups {
		i.Groups = append(i.Groups, group.Name)
	}

	sort.Strings(i.Groups)

	return i, nil
}
