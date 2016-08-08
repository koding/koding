package daemon

import (
	"fmt"
	"net"
	"strings"

	"github.com/Sirupsen/logrus"
	clustertypes "github.com/docker/docker/daemon/cluster/provider"
	"github.com/docker/docker/errors"
	"github.com/docker/docker/runconfig"
	"github.com/docker/engine-api/types"
	"github.com/docker/engine-api/types/network"
	"github.com/docker/libnetwork"
	networktypes "github.com/docker/libnetwork/types"
)

// NetworkControllerEnabled checks if the networking stack is enabled.
// This feature depends on OS primitives and it's disabled in systems like Windows.
func (daemon *Daemon) NetworkControllerEnabled() bool {
	return daemon.netController != nil
}

// FindNetwork function finds a network for a given string that can represent network name or id
func (daemon *Daemon) FindNetwork(idName string) (libnetwork.Network, error) {
	// Find by Name
	n, err := daemon.GetNetworkByName(idName)
	if err != nil && !isNoSuchNetworkError(err) {
		return nil, err
	}

	if n != nil {
		return n, nil
	}

	// Find by id
	return daemon.GetNetworkByID(idName)
}

func isNoSuchNetworkError(err error) bool {
	_, ok := err.(libnetwork.ErrNoSuchNetwork)
	return ok
}

// GetNetworkByID function returns a network whose ID begins with the given prefix.
// It fails with an error if no matching, or more than one matching, networks are found.
func (daemon *Daemon) GetNetworkByID(partialID string) (libnetwork.Network, error) {
	list := daemon.GetNetworksByID(partialID)

	if len(list) == 0 {
		return nil, libnetwork.ErrNoSuchNetwork(partialID)
	}
	if len(list) > 1 {
		return nil, libnetwork.ErrInvalidID(partialID)
	}
	return list[0], nil
}

// GetNetworkByName function returns a network for a given network name.
func (daemon *Daemon) GetNetworkByName(name string) (libnetwork.Network, error) {
	c := daemon.netController
	if c == nil {
		return nil, libnetwork.ErrNoSuchNetwork(name)
	}
	if name == "" {
		name = c.Config().Daemon.DefaultNetwork
	}
	return c.NetworkByName(name)
}

// GetNetworksByID returns a list of networks whose ID partially matches zero or more networks
func (daemon *Daemon) GetNetworksByID(partialID string) []libnetwork.Network {
	c := daemon.netController
	if c == nil {
		return nil
	}
	list := []libnetwork.Network{}
	l := func(nw libnetwork.Network) bool {
		if strings.HasPrefix(nw.ID(), partialID) {
			list = append(list, nw)
		}
		return false
	}
	c.WalkNetworks(l)

	return list
}

// getAllNetworks returns a list containing all networks
func (daemon *Daemon) getAllNetworks() []libnetwork.Network {
	c := daemon.netController
	list := []libnetwork.Network{}
	l := func(nw libnetwork.Network) bool {
		list = append(list, nw)
		return false
	}
	c.WalkNetworks(l)

	return list
}

func isIngressNetwork(name string) bool {
	return name == "ingress"
}

var ingressChan = make(chan struct{}, 1)

func ingressWait() func() {
	ingressChan <- struct{}{}
	return func() { <-ingressChan }
}

// SetupIngress setups ingress networking.
func (daemon *Daemon) SetupIngress(create clustertypes.NetworkCreateRequest, nodeIP string) error {
	ip, _, err := net.ParseCIDR(nodeIP)
	if err != nil {
		return err
	}

	go func() {
		controller := daemon.netController
		controller.AgentInitWait()

		if n, err := daemon.GetNetworkByName(create.Name); err == nil && n != nil && n.ID() != create.ID {
			if err := controller.SandboxDestroy("ingress-sbox"); err != nil {
				logrus.Errorf("Failed to delete stale ingress sandbox: %v", err)
				return
			}

			// Cleanup any stale endpoints that might be left over during previous iterations
			epList := n.Endpoints()
			for _, ep := range epList {
				if err := ep.Delete(true); err != nil {
					logrus.Errorf("Failed to delete endpoint %s (%s): %v", ep.Name(), ep.ID(), err)
				}
			}

			if err := n.Delete(); err != nil {
				logrus.Errorf("Failed to delete stale ingress network %s: %v", n.ID(), err)
				return
			}
		}

		if _, err := daemon.createNetwork(create.NetworkCreateRequest, create.ID, true); err != nil {
			// If it is any other error other than already
			// exists error log error and return.
			if _, ok := err.(libnetwork.NetworkNameError); !ok {
				logrus.Errorf("Failed creating ingress network: %v", err)
				return
			}

			// Otherwise continue down the call to create or recreate sandbox.
		}

		n, err := daemon.GetNetworkByID(create.ID)
		if err != nil {
			logrus.Errorf("Failed getting ingress network by id after creating: %v", err)
			return
		}

		sb, err := controller.NewSandbox("ingress-sbox", libnetwork.OptionIngress())
		if err != nil {
			if _, ok := err.(networktypes.ForbiddenError); !ok {
				logrus.Errorf("Failed creating ingress sandbox: %v", err)
			}
			return
		}

		ep, err := n.CreateEndpoint("ingress-endpoint", libnetwork.CreateOptionIpam(ip, nil, nil, nil))
		if err != nil {
			logrus.Errorf("Failed creating ingress endpoint: %v", err)
			return
		}

		if err := ep.Join(sb, nil); err != nil {
			logrus.Errorf("Failed joining ingress sandbox to ingress endpoint: %v", err)
		}
	}()

	return nil
}

// SetNetworkBootstrapKeys sets the bootstrap keys.
func (daemon *Daemon) SetNetworkBootstrapKeys(keys []*networktypes.EncryptionKey) error {
	return daemon.netController.SetKeys(keys)
}

// CreateManagedNetwork creates an agent network.
func (daemon *Daemon) CreateManagedNetwork(create clustertypes.NetworkCreateRequest) error {
	_, err := daemon.createNetwork(create.NetworkCreateRequest, create.ID, true)
	return err
}

// CreateNetwork creates a network with the given name, driver and other optional parameters
func (daemon *Daemon) CreateNetwork(create types.NetworkCreateRequest) (*types.NetworkCreateResponse, error) {
	resp, err := daemon.createNetwork(create, "", false)
	if err != nil {
		return nil, err
	}
	return resp, err
}

func (daemon *Daemon) createNetwork(create types.NetworkCreateRequest, id string, agent bool) (*types.NetworkCreateResponse, error) {
	// If there is a pending ingress network creation wait here
	// since ingress network creation can happen via node download
	// from manager or task download.
	if isIngressNetwork(create.Name) {
		defer ingressWait()()
	}

	if runconfig.IsPreDefinedNetwork(create.Name) && !agent {
		err := fmt.Errorf("%s is a pre-defined network and cannot be created", create.Name)
		return nil, errors.NewRequestForbiddenError(err)
	}

	var warning string
	nw, err := daemon.GetNetworkByName(create.Name)
	if err != nil {
		if _, ok := err.(libnetwork.ErrNoSuchNetwork); !ok {
			return nil, err
		}
	}
	if nw != nil {
		if create.CheckDuplicate {
			return nil, libnetwork.NetworkNameError(create.Name)
		}
		warning = fmt.Sprintf("Network with name %s (id : %s) already exists", nw.Name(), nw.ID())
	}

	c := daemon.netController
	driver := create.Driver
	if driver == "" {
		driver = c.Config().Daemon.DefaultDriver
	}

	ipam := create.IPAM
	v4Conf, v6Conf, err := getIpamConfig(ipam.Config)
	if err != nil {
		return nil, err
	}

	nwOptions := []libnetwork.NetworkOption{
		libnetwork.NetworkOptionIpam(ipam.Driver, "", v4Conf, v6Conf, ipam.Options),
		libnetwork.NetworkOptionEnableIPv6(create.EnableIPv6),
		libnetwork.NetworkOptionDriverOpts(create.Options),
		libnetwork.NetworkOptionLabels(create.Labels),
	}
	if create.Internal {
		nwOptions = append(nwOptions, libnetwork.NetworkOptionInternalNetwork())
	}
	if agent {
		nwOptions = append(nwOptions, libnetwork.NetworkOptionDynamic())
		nwOptions = append(nwOptions, libnetwork.NetworkOptionPersist(false))
	}

	if isIngressNetwork(create.Name) {
		nwOptions = append(nwOptions, libnetwork.NetworkOptionIngress())
	}

	n, err := c.NewNetwork(driver, create.Name, id, nwOptions...)
	if err != nil {
		return nil, err
	}

	daemon.LogNetworkEvent(n, "create")
	return &types.NetworkCreateResponse{
		ID:      n.ID(),
		Warning: warning,
	}, nil
}

func getIpamConfig(data []network.IPAMConfig) ([]*libnetwork.IpamConf, []*libnetwork.IpamConf, error) {
	ipamV4Cfg := []*libnetwork.IpamConf{}
	ipamV6Cfg := []*libnetwork.IpamConf{}
	for _, d := range data {
		iCfg := libnetwork.IpamConf{}
		iCfg.PreferredPool = d.Subnet
		iCfg.SubPool = d.IPRange
		iCfg.Gateway = d.Gateway
		iCfg.AuxAddresses = d.AuxAddress
		ip, _, err := net.ParseCIDR(d.Subnet)
		if err != nil {
			return nil, nil, fmt.Errorf("Invalid subnet %s : %v", d.Subnet, err)
		}
		if ip.To4() != nil {
			ipamV4Cfg = append(ipamV4Cfg, &iCfg)
		} else {
			ipamV6Cfg = append(ipamV6Cfg, &iCfg)
		}
	}
	return ipamV4Cfg, ipamV6Cfg, nil
}

// UpdateContainerServiceConfig updates a service configuration.
func (daemon *Daemon) UpdateContainerServiceConfig(containerName string, serviceConfig *clustertypes.ServiceConfig) error {
	container, err := daemon.GetContainer(containerName)
	if err != nil {
		return err
	}

	container.NetworkSettings.Service = serviceConfig
	return nil
}

// ConnectContainerToNetwork connects the given container to the given
// network. If either cannot be found, an err is returned. If the
// network cannot be set up, an err is returned.
func (daemon *Daemon) ConnectContainerToNetwork(containerName, networkName string, endpointConfig *network.EndpointSettings) error {
	container, err := daemon.GetContainer(containerName)
	if err != nil {
		return err
	}
	return daemon.ConnectToNetwork(container, networkName, endpointConfig)
}

// DisconnectContainerFromNetwork disconnects the given container from
// the given network. If either cannot be found, an err is returned.
func (daemon *Daemon) DisconnectContainerFromNetwork(containerName string, network libnetwork.Network, force bool) error {
	container, err := daemon.GetContainer(containerName)
	if err != nil {
		if force {
			return daemon.ForceEndpointDelete(containerName, network)
		}
		return err
	}
	return daemon.DisconnectFromNetwork(container, network, force)
}

// GetNetworkDriverList returns the list of plugins drivers
// registered for network.
func (daemon *Daemon) GetNetworkDriverList() map[string]bool {
	pluginList := make(map[string]bool)

	if !daemon.NetworkControllerEnabled() {
		return nil
	}
	c := daemon.netController
	networks := c.Networks()

	for _, network := range networks {
		driver := network.Type()
		pluginList[driver] = true
	}
	// TODO : Replace this with proper libnetwork API
	pluginList["overlay"] = true

	return pluginList
}

// DeleteManagedNetwork deletes an agent network.
func (daemon *Daemon) DeleteManagedNetwork(networkID string) error {
	return daemon.deleteNetwork(networkID, true)
}

// DeleteNetwork destroys a network unless it's one of docker's predefined networks.
func (daemon *Daemon) DeleteNetwork(networkID string) error {
	return daemon.deleteNetwork(networkID, false)
}

func (daemon *Daemon) deleteNetwork(networkID string, dynamic bool) error {
	nw, err := daemon.FindNetwork(networkID)
	if err != nil {
		return err
	}

	if runconfig.IsPreDefinedNetwork(nw.Name()) && !dynamic {
		err := fmt.Errorf("%s is a pre-defined network and cannot be removed", nw.Name())
		return errors.NewRequestForbiddenError(err)
	}

	if err := nw.Delete(); err != nil {
		return err
	}
	daemon.LogNetworkEvent(nw, "destroy")
	return nil
}

// GetNetworks returns a list of all networks
func (daemon *Daemon) GetNetworks() []libnetwork.Network {
	return daemon.getAllNetworks()
}
