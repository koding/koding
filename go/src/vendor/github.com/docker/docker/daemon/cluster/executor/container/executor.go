package container

import (
	"strings"

	executorpkg "github.com/docker/docker/daemon/cluster/executor"
	clustertypes "github.com/docker/docker/daemon/cluster/provider"
	"github.com/docker/engine-api/types"
	"github.com/docker/engine-api/types/network"
	networktypes "github.com/docker/libnetwork/types"
	"github.com/docker/swarmkit/agent/exec"
	"github.com/docker/swarmkit/api"
	"golang.org/x/net/context"
)

type executor struct {
	backend executorpkg.Backend
}

// NewExecutor returns an executor from the docker client.
func NewExecutor(b executorpkg.Backend) exec.Executor {
	return &executor{
		backend: b,
	}
}

// Describe returns the underlying node description from the docker client.
func (e *executor) Describe(ctx context.Context) (*api.NodeDescription, error) {
	info, err := e.backend.SystemInfo()
	if err != nil {
		return nil, err
	}

	var plugins []api.PluginDescription
	addPlugins := func(typ string, names []string) {
		for _, name := range names {
			plugins = append(plugins, api.PluginDescription{
				Type: typ,
				Name: name,
			})
		}
	}

	addPlugins("Volume", info.Plugins.Volume)
	// Add builtin driver "overlay" (the only builtin multi-host driver) to
	// the plugin list by default.
	addPlugins("Network", append([]string{"overlay"}, info.Plugins.Network...))
	addPlugins("Authorization", info.Plugins.Authorization)

	// parse []string labels into a map[string]string
	labels := map[string]string{}
	for _, l := range info.Labels {
		stringSlice := strings.SplitN(l, "=", 2)
		// this will take the last value in the list for a given key
		// ideally, one shouldn't assign multiple values to the same key
		if len(stringSlice) > 1 {
			labels[stringSlice[0]] = stringSlice[1]
		}
	}

	description := &api.NodeDescription{
		Hostname: info.Name,
		Platform: &api.Platform{
			Architecture: info.Architecture,
			OS:           info.OSType,
		},
		Engine: &api.EngineDescription{
			EngineVersion: info.ServerVersion,
			Labels:        labels,
			Plugins:       plugins,
		},
		Resources: &api.Resources{
			NanoCPUs:    int64(info.NCPU) * 1e9,
			MemoryBytes: info.MemTotal,
		},
	}

	return description, nil
}

func (e *executor) Configure(ctx context.Context, node *api.Node) error {
	na := node.Attachment
	if na == nil {
		return nil
	}

	options := types.NetworkCreate{
		Driver: na.Network.DriverState.Name,
		IPAM: network.IPAM{
			Driver: na.Network.IPAM.Driver.Name,
		},
		Options:        na.Network.DriverState.Options,
		CheckDuplicate: true,
	}

	for _, ic := range na.Network.IPAM.Configs {
		c := network.IPAMConfig{
			Subnet:  ic.Subnet,
			IPRange: ic.Range,
			Gateway: ic.Gateway,
		}
		options.IPAM.Config = append(options.IPAM.Config, c)
	}

	return e.backend.SetupIngress(clustertypes.NetworkCreateRequest{
		na.Network.ID,
		types.NetworkCreateRequest{
			Name:          na.Network.Spec.Annotations.Name,
			NetworkCreate: options,
		},
	}, na.Addresses[0])
}

// Controller returns a docker container runner.
func (e *executor) Controller(t *api.Task) (exec.Controller, error) {
	ctlr, err := newController(e.backend, t)
	if err != nil {
		return nil, err
	}

	return ctlr, nil
}

func (e *executor) SetNetworkBootstrapKeys(keys []*api.EncryptionKey) error {
	nwKeys := []*networktypes.EncryptionKey{}
	for _, key := range keys {
		nwKey := &networktypes.EncryptionKey{
			Subsystem:   key.Subsystem,
			Algorithm:   int32(key.Algorithm),
			Key:         make([]byte, len(key.Key)),
			LamportTime: key.LamportTime,
		}
		copy(nwKey.Key, key.Key)
		nwKeys = append(nwKeys, nwKey)
	}
	e.backend.SetNetworkBootstrapKeys(nwKeys)

	return nil
}
