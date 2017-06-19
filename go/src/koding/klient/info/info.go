package info

import (
	"runtime"
	"sort"

	"koding/kites/config"
	"github.com/koding/kite"
)

type InfoRequest struct {

	// Whether or not to perform whois lookup.
	Lookup			bool
}

type InfoResponse struct {
	// ProviderName is the name of the machine (vm or otherwise) provider,
	// as identified by the
	ProviderName	string		`json:"providerName"`

	Username        string  	`json:"username"`
	Home            string  	`json:"home"`
	Groups          []string	`json:"groups"`
	OS              string		`json:"os"`
	Arch            string		`json:"arch"`
}

type Infoer interface {
	Info(*kite.Request) (interface{}, error)
}

// Info implements the klient.info method, returning klient specific
// information about the machine klient is running within.
//
// See also `kite.info`.
func Info(r *kite.Request) (interface{}, error) {
	res := &InfoResponse{
		// ProviderName: 	providerName.String(),
		Username:     	config.CurrentUser.Username,
		Home:         	config.CurrentUser.HomeDir,
		OS:           	runtime.GOOS,
		Arch:         	runtime.GOARCH,
	}

	for _, group := range config.CurrentUser.Groups {
		res.Groups = append(res.Groups, group.Name)
	}
	sort.Strings(res.Groups)

	var req *InfoRequest

	err := r.Args.One().Unmarshal(&req)
	if err == nil && !req.Lookup {

		// If we were explicitly told not to perform a provider lookup,
		// then return UnknownProvider here.
		res.ProviderName = UnknownProvider.String()
		return res, nil
	}

	providerName, err := CheckProvider()
	if err != nil {
		return InfoResponse{}, err
	}
	res.ProviderName = providerName.String()

	return res, nil
}
