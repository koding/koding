package libnetwork

//go:generate protoc -I.:Godeps/_workspace/src/github.com/gogo/protobuf  --gogo_out=import_path=github.com/docker/libnetwork,Mgogoproto/gogo.proto=github.com/gogo/protobuf/gogoproto:. agent.proto

import (
	"fmt"
	"net"
	"os"
	"sort"

	"github.com/Sirupsen/logrus"
	"github.com/docker/go-events"
	"github.com/docker/libnetwork/datastore"
	"github.com/docker/libnetwork/discoverapi"
	"github.com/docker/libnetwork/driverapi"
	"github.com/docker/libnetwork/networkdb"
	"github.com/docker/libnetwork/types"
	"github.com/gogo/protobuf/proto"
)

const (
	subsysGossip = "networking:gossip"
	subsysIPSec  = "networking:ipsec"
	keyringSize  = 3
)

// ByTime implements sort.Interface for []*types.EncryptionKey based on
// the LamportTime field.
type ByTime []*types.EncryptionKey

func (b ByTime) Len() int           { return len(b) }
func (b ByTime) Swap(i, j int)      { b[i], b[j] = b[j], b[i] }
func (b ByTime) Less(i, j int) bool { return b[i].LamportTime < b[j].LamportTime }

type agent struct {
	networkDB         *networkdb.NetworkDB
	bindAddr          string
	epTblCancel       func()
	driverCancelFuncs map[string][]func()
}

func getBindAddr(ifaceName string) (string, error) {
	iface, err := net.InterfaceByName(ifaceName)
	if err != nil {
		return "", fmt.Errorf("failed to find interface %s: %v", ifaceName, err)
	}

	addrs, err := iface.Addrs()
	if err != nil {
		return "", fmt.Errorf("failed to get interface addresses: %v", err)
	}

	for _, a := range addrs {
		addr, ok := a.(*net.IPNet)
		if !ok {
			continue
		}
		addrIP := addr.IP

		if addrIP.IsLinkLocalUnicast() {
			continue
		}

		return addrIP.String(), nil
	}

	return "", fmt.Errorf("failed to get bind address")
}

func resolveAddr(addrOrInterface string) (string, error) {
	// Try and see if this is a valid IP address
	if net.ParseIP(addrOrInterface) != nil {
		return addrOrInterface, nil
	}

	addr, err := net.ResolveIPAddr("ip", addrOrInterface)
	if err != nil {
		// If not a valid IP address, it should be a valid interface
		return getBindAddr(addrOrInterface)
	}
	return addr.String(), nil
}

func (c *controller) handleKeyChange(keys []*types.EncryptionKey) error {
	drvEnc := discoverapi.DriverEncryptionUpdate{}

	a := c.agent
	// Find the deleted key. If the deleted key was the primary key,
	// a new primary key should be set before removing if from keyring.
	deleted := []byte{}
	j := len(c.keys)
	for i := 0; i < j; {
		same := false
		for _, key := range keys {
			if same = key.LamportTime == c.keys[i].LamportTime; same {
				break
			}
		}
		if !same {
			cKey := c.keys[i]
			if cKey.Subsystem == subsysGossip {
				deleted = cKey.Key
			}

			if cKey.Subsystem == subsysIPSec {
				drvEnc.Prune = cKey.Key
				drvEnc.PruneTag = cKey.LamportTime
			}
			c.keys[i], c.keys[j-1] = c.keys[j-1], c.keys[i]
			c.keys[j-1] = nil
			j--
		}
		i++
	}
	c.keys = c.keys[:j]

	// Find the new key and add it to the key ring
	for _, key := range keys {
		same := false
		for _, cKey := range c.keys {
			if same = cKey.LamportTime == key.LamportTime; same {
				break
			}
		}
		if !same {
			c.keys = append(c.keys, key)
			if key.Subsystem == subsysGossip {
				a.networkDB.SetKey(key.Key)
			}

			if key.Subsystem == subsysIPSec {
				drvEnc.Key = key.Key
				drvEnc.Tag = key.LamportTime
			}
		}
	}

	key, tag := c.getPrimaryKeyTag(subsysGossip)
	a.networkDB.SetPrimaryKey(key)

	key, tag = c.getPrimaryKeyTag(subsysIPSec)
	drvEnc.Primary = key
	drvEnc.PrimaryTag = tag

	if len(deleted) > 0 {
		a.networkDB.RemoveKey(deleted)
	}

	c.drvRegistry.WalkDrivers(func(name string, driver driverapi.Driver, capability driverapi.Capability) bool {
		err := driver.DiscoverNew(discoverapi.EncryptionKeysUpdate, drvEnc)
		if err != nil {
			logrus.Warnf("Failed to update datapath keys in driver %s: %v", name, err)
		}
		return false
	})

	return nil
}

func (c *controller) handleKeyChangeV1(keys []*types.EncryptionKey) error {
	drvEnc := discoverapi.DriverEncryptionUpdate{}

	// Find the new key and add it to the key ring
	a := c.agent
	for _, key := range keys {
		same := false
		for _, cKey := range c.keys {
			if same = cKey.LamportTime == key.LamportTime; same {
				break
			}
		}
		if !same {
			c.keys = append(c.keys, key)
			if key.Subsystem == subsysGossip {
				a.networkDB.SetKey(key.Key)
			}
			if key.Subsystem == subsysGossip /*subsysIPSec*/ {
				drvEnc.Key = key.Key
				drvEnc.Tag = key.LamportTime
			}
			break
		}
	}
	// Find the deleted key. If the deleted key was the primary key,
	// a new primary key should be set before removing if from keyring.
	deleted := []byte{}
	for i, cKey := range c.keys {
		same := false
		for _, key := range keys {
			if same = key.LamportTime == cKey.LamportTime; same {
				break
			}
		}
		if !same {
			if cKey.Subsystem == subsysGossip {
				deleted = cKey.Key
			}
			if cKey.Subsystem == subsysGossip /*subsysIPSec*/ {
				drvEnc.Prune = cKey.Key
				drvEnc.PruneTag = cKey.LamportTime
			}
			c.keys = append(c.keys[:i], c.keys[i+1:]...)
			break
		}
	}

	sort.Sort(ByTime(c.keys))
	for _, key := range c.keys {
		if key.Subsystem == subsysGossip {
			a.networkDB.SetPrimaryKey(key.Key)
			break
		}
	}
	for _, key := range c.keys {
		if key.Subsystem == subsysGossip /*subsysIPSec*/ {
			drvEnc.Primary = key.Key
			drvEnc.PrimaryTag = key.LamportTime
			break
		}
	}
	if len(deleted) > 0 {
		a.networkDB.RemoveKey(deleted)
	}

	c.drvRegistry.WalkDrivers(func(name string, driver driverapi.Driver, capability driverapi.Capability) bool {
		err := driver.DiscoverNew(discoverapi.EncryptionKeysUpdate, drvEnc)
		if err != nil {
			logrus.Warnf("Failed to update datapath keys in driver %s: %v", name, err)
		}
		return false
	})

	return nil
}

func (c *controller) agentSetup() error {
	clusterProvider := c.cfg.Daemon.ClusterProvider

	bindAddr, _, _ := net.SplitHostPort(clusterProvider.GetListenAddress())
	remote := clusterProvider.GetRemoteAddress()
	remoteAddr, _, _ := net.SplitHostPort(remote)

	// Determine the BindAddress from RemoteAddress or through best-effort routing
	if !isValidClusteringIP(bindAddr) {
		if !isValidClusteringIP(remoteAddr) {
			remote = "8.8.8.8:53"
		}
		conn, err := net.Dial("udp", remote)
		if err == nil {
			bindHostPort := conn.LocalAddr().String()
			bindAddr, _, _ = net.SplitHostPort(bindHostPort)
			conn.Close()
		}
	}

	if bindAddr != "" && c.agent == nil {
		if err := c.agentInit(bindAddr); err != nil {
			logrus.Errorf("Error in agentInit : %v", err)
		} else {
			c.drvRegistry.WalkDrivers(func(name string, driver driverapi.Driver, capability driverapi.Capability) bool {
				if capability.DataScope == datastore.GlobalScope {
					c.agentDriverNotify(driver)
				}
				return false
			})

			if c.agent != nil {
				close(c.agentInitDone)
			}
		}
	}
	if remoteAddr != "" {
		if err := c.agentJoin(remoteAddr); err != nil {
			logrus.Errorf("Error in agentJoin : %v", err)
		}
	}
	return nil
}

// For a given subsystem getKeys sorts the keys by lamport time and returns
// slice of keys and lamport time which can used as a unique tag for the keys
func (c *controller) getKeys(subsys string) ([][]byte, []uint64) {
	sort.Sort(ByTime(c.keys))

	keys := [][]byte{}
	tags := []uint64{}
	for _, key := range c.keys {
		if key.Subsystem == subsys {
			keys = append(keys, key.Key)
			tags = append(tags, key.LamportTime)
		}
	}

	if len(keys) < keyringSize {
		return keys, tags
	}
	keys[0], keys[1] = keys[1], keys[0]
	tags[0], tags[1] = tags[1], tags[0]
	return keys, tags
}

// getPrimaryKeyTag returns the primary key for a given subsytem from the
// list of sorted key and the associated tag
func (c *controller) getPrimaryKeyTag(subsys string) ([]byte, uint64) {
	sort.Sort(ByTime(c.keys))
	keys := []*types.EncryptionKey{}
	for _, key := range c.keys {
		if key.Subsystem == subsys {
			keys = append(keys, key)
		}
	}
	return keys[1].Key, keys[1].LamportTime
}

func (c *controller) agentInit(bindAddrOrInterface string) error {
	if !c.isAgent() {
		return nil
	}

	bindAddr, err := resolveAddr(bindAddrOrInterface)
	if err != nil {
		return err
	}

	keys, tags := c.getKeys(subsysGossip)
	hostname, _ := os.Hostname()
	nDB, err := networkdb.New(&networkdb.Config{
		BindAddr: bindAddr,
		NodeName: hostname,
		Keys:     keys,
	})

	if err != nil {
		return err
	}

	ch, cancel := nDB.Watch("endpoint_table", "", "")

	c.agent = &agent{
		networkDB:         nDB,
		bindAddr:          bindAddr,
		epTblCancel:       cancel,
		driverCancelFuncs: make(map[string][]func()),
	}

	go c.handleTableEvents(ch, c.handleEpTableEvent)

	drvEnc := discoverapi.DriverEncryptionConfig{}
	keys, tags = c.getKeys(subsysIPSec)
	drvEnc.Keys = keys
	drvEnc.Tags = tags

	c.drvRegistry.WalkDrivers(func(name string, driver driverapi.Driver, capability driverapi.Capability) bool {
		err := driver.DiscoverNew(discoverapi.EncryptionKeysConfig, drvEnc)
		if err != nil {
			logrus.Warnf("Failed to set datapath keys in driver %s: %v", name, err)
		}
		return false
	})

	c.WalkNetworks(joinCluster)

	return nil
}

func (c *controller) agentJoin(remote string) error {
	if c.agent == nil {
		return nil
	}

	return c.agent.networkDB.Join([]string{remote})
}

func (c *controller) agentDriverNotify(d driverapi.Driver) {
	if c.agent == nil {
		return
	}

	d.DiscoverNew(discoverapi.NodeDiscovery, discoverapi.NodeDiscoveryData{
		Address: c.agent.bindAddr,
		Self:    true,
	})

	drvEnc := discoverapi.DriverEncryptionConfig{}
	keys, tags := c.getKeys(subsysIPSec)
	drvEnc.Keys = keys
	drvEnc.Tags = tags

	c.drvRegistry.WalkDrivers(func(name string, driver driverapi.Driver, capability driverapi.Capability) bool {
		err := driver.DiscoverNew(discoverapi.EncryptionKeysConfig, drvEnc)
		if err != nil {
			logrus.Warnf("Failed to set datapath keys in driver %s: %v", name, err)
		}
		return false
	})

}

func (c *controller) agentClose() {
	if c.agent == nil {
		return
	}

	for _, cancelFuncs := range c.agent.driverCancelFuncs {
		for _, cancel := range cancelFuncs {
			cancel()
		}
	}
	c.agent.epTblCancel()

	c.agent.networkDB.Close()
	c.agent = nil
}

func (n *network) isClusterEligible() bool {
	if n.driverScope() != datastore.GlobalScope {
		return false
	}

	c := n.getController()
	if c.agent == nil {
		return false
	}

	return true
}

func (n *network) joinCluster() error {
	if !n.isClusterEligible() {
		return nil
	}

	c := n.getController()
	return c.agent.networkDB.JoinNetwork(n.ID())
}

func (n *network) leaveCluster() error {
	if !n.isClusterEligible() {
		return nil
	}

	c := n.getController()
	return c.agent.networkDB.LeaveNetwork(n.ID())
}

func (ep *endpoint) addToCluster() error {
	n := ep.getNetwork()
	if !n.isClusterEligible() {
		return nil
	}

	c := n.getController()
	if !ep.isAnonymous() && ep.Iface().Address() != nil {
		var ingressPorts []*PortConfig
		if ep.svcID != "" {
			// Gossip ingress ports only in ingress network.
			if n.ingress {
				ingressPorts = ep.ingressPorts
			}

			if err := c.addServiceBinding(ep.svcName, ep.svcID, n.ID(), ep.ID(), ep.virtualIP, ingressPorts, ep.svcAliases, ep.Iface().Address().IP); err != nil {
				return err
			}
		}

		buf, err := proto.Marshal(&EndpointRecord{
			Name:         ep.Name(),
			ServiceName:  ep.svcName,
			ServiceID:    ep.svcID,
			VirtualIP:    ep.virtualIP.String(),
			IngressPorts: ingressPorts,
			Aliases:      ep.svcAliases,
			EndpointIP:   ep.Iface().Address().IP.String(),
		})

		if err != nil {
			return err
		}

		if err := c.agent.networkDB.CreateEntry("endpoint_table", n.ID(), ep.ID(), buf); err != nil {
			return err
		}
	}

	for _, te := range ep.joinInfo.driverTableEntries {
		if err := c.agent.networkDB.CreateEntry(te.tableName, n.ID(), te.key, te.value); err != nil {
			return err
		}
	}

	return nil
}

func (ep *endpoint) deleteFromCluster() error {
	n := ep.getNetwork()
	if !n.isClusterEligible() {
		return nil
	}

	c := n.getController()
	if !ep.isAnonymous() {
		if ep.svcID != "" && ep.Iface().Address() != nil {
			var ingressPorts []*PortConfig
			if n.ingress {
				ingressPorts = ep.ingressPorts
			}

			if err := c.rmServiceBinding(ep.svcName, ep.svcID, n.ID(), ep.ID(), ep.virtualIP, ingressPorts, ep.svcAliases, ep.Iface().Address().IP); err != nil {
				return err
			}
		}

		if err := c.agent.networkDB.DeleteEntry("endpoint_table", n.ID(), ep.ID()); err != nil {
			return err
		}
	}

	if ep.joinInfo == nil {
		return nil
	}

	for _, te := range ep.joinInfo.driverTableEntries {
		if err := c.agent.networkDB.DeleteEntry(te.tableName, n.ID(), te.key); err != nil {
			return err
		}
	}

	return nil
}

func (n *network) addDriverWatches() {
	if !n.isClusterEligible() {
		return
	}

	c := n.getController()
	for _, tableName := range n.driverTables {
		ch, cancel := c.agent.networkDB.Watch(tableName, n.ID(), "")
		c.Lock()
		c.agent.driverCancelFuncs[n.ID()] = append(c.agent.driverCancelFuncs[n.ID()], cancel)
		c.Unlock()

		go c.handleTableEvents(ch, n.handleDriverTableEvent)
		d, err := n.driver(false)
		if err != nil {
			logrus.Errorf("Could not resolve driver %s while walking driver tabl: %v", n.networkType, err)
			return
		}

		c.agent.networkDB.WalkTable(tableName, func(nid, key string, value []byte) bool {
			d.EventNotify(driverapi.Create, n.ID(), tableName, key, value)
			return false
		})
	}
}

func (n *network) cancelDriverWatches() {
	if !n.isClusterEligible() {
		return
	}

	c := n.getController()
	c.Lock()
	cancelFuncs := c.agent.driverCancelFuncs[n.ID()]
	delete(c.agent.driverCancelFuncs, n.ID())
	c.Unlock()

	for _, cancel := range cancelFuncs {
		cancel()
	}
}

func (c *controller) handleTableEvents(ch chan events.Event, fn func(events.Event)) {
	for {
		select {
		case ev, ok := <-ch:
			if !ok {
				return
			}

			fn(ev)
		}
	}
}

func (n *network) handleDriverTableEvent(ev events.Event) {
	d, err := n.driver(false)
	if err != nil {
		logrus.Errorf("Could not resolve driver %s while handling driver table event: %v", n.networkType, err)
		return
	}

	var (
		etype driverapi.EventType
		tname string
		key   string
		value []byte
	)

	switch event := ev.(type) {
	case networkdb.CreateEvent:
		tname = event.Table
		key = event.Key
		value = event.Value
		etype = driverapi.Create
	case networkdb.DeleteEvent:
		tname = event.Table
		key = event.Key
		value = event.Value
		etype = driverapi.Delete
	case networkdb.UpdateEvent:
		tname = event.Table
		key = event.Key
		value = event.Value
		etype = driverapi.Delete
	}

	d.EventNotify(etype, n.ID(), tname, key, value)
}

func (c *controller) handleEpTableEvent(ev events.Event) {
	var (
		nid   string
		eid   string
		value []byte
		isAdd bool
		epRec EndpointRecord
	)

	switch event := ev.(type) {
	case networkdb.CreateEvent:
		nid = event.NetworkID
		eid = event.Key
		value = event.Value
		isAdd = true
	case networkdb.DeleteEvent:
		nid = event.NetworkID
		eid = event.Key
		value = event.Value
	case networkdb.UpdateEvent:
		logrus.Errorf("Unexpected update service table event = %#v", event)
	}

	nw, err := c.NetworkByID(nid)
	if err != nil {
		logrus.Errorf("Could not find network %s while handling service table event: %v", nid, err)
		return
	}
	n := nw.(*network)

	err = proto.Unmarshal(value, &epRec)
	if err != nil {
		logrus.Errorf("Failed to unmarshal service table value: %v", err)
		return
	}

	name := epRec.Name
	svcName := epRec.ServiceName
	svcID := epRec.ServiceID
	vip := net.ParseIP(epRec.VirtualIP)
	ip := net.ParseIP(epRec.EndpointIP)
	ingressPorts := epRec.IngressPorts
	aliases := epRec.Aliases

	if name == "" || ip == nil {
		logrus.Errorf("Invalid endpoint name/ip received while handling service table event %s", value)
		return
	}

	if isAdd {
		if svcID != "" {
			if err := c.addServiceBinding(svcName, svcID, nid, eid, vip, ingressPorts, aliases, ip); err != nil {
				logrus.Errorf("Failed adding service binding for value %s: %v", value, err)
				return
			}
		}

		n.addSvcRecords(name, ip, nil, true)
	} else {
		if svcID != "" {
			if err := c.rmServiceBinding(svcName, svcID, nid, eid, vip, ingressPorts, aliases, ip); err != nil {
				logrus.Errorf("Failed adding service binding for value %s: %v", value, err)
				return
			}
		}

		n.deleteSvcRecords(name, ip, nil, true)
	}
}
