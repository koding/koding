//
// gosdc - Go library to interact with the Joyent CloudAPI
//
// CloudAPI double testing service - internal direct API implementation
//
// Copyright (c) Joyent Inc.
//

package cloudapi

import (
	"fmt"
	"math/rand"
	"net/url"
	"strings"
	"time"

	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosdc/localservices"
)

var (
	separator       = "/"
	packagesFilters = []string{"name", "memory", "disk", "swap", "version", "vcpus", "group"}
	imagesFilters   = []string{"name", "os", "version", "public", "state", "owner", "type"}
	machinesFilters = []string{"type", "name", "image", "state", "memory", "tombstone", "limit", "offset", "credentials"}
)

// CloudAPI is the API test double
type CloudAPI struct {
	localservices.ServiceInstance
	keys          []cloudapi.Key
	packages      []cloudapi.Package
	images        []cloudapi.Image
	machines      []*machine
	snapshots     map[string][]cloudapi.Snapshot
	firewallRules []*cloudapi.FirewallRule
	networks      []cloudapi.Network
	fabricVLANs   map[int16]*fabricVLAN
}

type machine struct {
	cloudapi.Machine
	NICs        map[string]*cloudapi.NIC `json:"-"`
	NetworkNICs map[string]string        `json:"-"`
}

// fabricNetwork is a container for a fabric network and it's associated VLANs
type fabricVLAN struct {
	cloudapi.FabricVLAN
	Networks map[string]*cloudapi.FabricNetwork `json:"-"`
}

// New makes a new *CloudAPI service with the given information
func New(serviceURL, userAccount string) *CloudAPI {
	URL, err := url.Parse(serviceURL)
	if err != nil {
		panic(err)
	}
	hostname := URL.Host
	if !strings.HasSuffix(hostname, separator) {
		hostname += separator
	}

	var (
		keys          []cloudapi.Key
		machines      []*machine
		snapshots     = map[string][]cloudapi.Snapshot{}
		firewallRules []*cloudapi.FirewallRule
		fabricVLANs   = map[int16]*fabricVLAN{}
	)

	cloudapiService := &CloudAPI{
		keys:          keys,
		packages:      initPackages(),
		images:        initImages(),
		machines:      machines,
		snapshots:     snapshots,
		firewallRules: firewallRules,
		fabricVLANs:   fabricVLANs,
		networks: []cloudapi.Network{
			{Id: "123abc4d-0011-aabb-2233-ccdd4455", Name: "Test-Joyent-Public", Public: true},
			{Id: "456def0a-33ff-7f8e-9a0b-33bb44cc", Name: "Test-Joyent-Private", Public: false},
		},
		ServiceInstance: localservices.ServiceInstance{
			Scheme:      URL.Scheme,
			Hostname:    hostname,
			UserAccount: userAccount,
		},
	}

	return cloudapiService
}

func initPackages() []cloudapi.Package {
	return []cloudapi.Package{
		{
			Name:    "Micro",
			Memory:  512,
			Disk:    8192,
			Swap:    1024,
			VCPUs:   1,
			Default: false,
			Id:      "12345678-aaaa-bbbb-cccc-000000000000",
			Version: "1.0.0",
		},
		{
			Name:    "Small",
			Memory:  1024,
			Disk:    16384,
			Swap:    2048,
			VCPUs:   1,
			Default: true,
			Id:      "11223344-1212-abab-3434-aabbccddeeff",
			Version: "1.0.2",
		},
		{
			Name:    "Medium",
			Memory:  2048,
			Disk:    32768,
			Swap:    4096,
			VCPUs:   2,
			Default: false,
			Id:      "aabbccdd-abcd-abcd-abcd-112233445566",
			Version: "1.0.4",
		},
		{
			Name:    "Large",
			Memory:  4096,
			Disk:    65536,
			Swap:    16384,
			VCPUs:   4,
			Default: false,
			Id:      "00998877-dddd-eeee-ffff-111111111111",
			Version: "1.0.1",
		},
	}
}

func initImages() []cloudapi.Image {
	return []cloudapi.Image{
		{
			Id:          "12345678-a1a1-b2b2-c3c3-098765432100",
			Name:        "SmartOS Std",
			OS:          "smartos",
			Version:     "13.3.1",
			Type:        "smartmachine",
			Description: "Test SmartOS image (32 bit)",
			Homepage:    "http://test.joyent.com/Standard_Instance",
			PublishedAt: "2014-01-08T17:42:31Z",
			Public:      true,
			State:       "active",
		},
		{
			Id:          "12345678-b1b1-a4a4-d8d8-111111999999",
			Name:        "standard32",
			OS:          "smartos",
			Version:     "13.3.1",
			Type:        "smartmachine",
			Description: "Test SmartOS image (64 bit)",
			Homepage:    "http://test.joyent.com/Standard_Instance",
			PublishedAt: "2014-01-08T17:43:16Z",
			Public:      true,
			State:       "active",
		},
		{
			Id:          "a1b2c3d4-0011-2233-4455-0f1e2d3c4b5a",
			Name:        "centos6.4",
			OS:          "linux",
			Version:     "2.4.1",
			Type:        "virtualmachine",
			Description: "Test CentOS 6.4 image (64 bit)",
			PublishedAt: "2014-01-02T10:58:31Z",
			Public:      true,
			State:       "active",
		},
		{
			Id:          "11223344-0a0a-ff99-11bb-0a1b2c3d4e5f",
			Name:        "ubuntu12.04",
			OS:          "linux",
			Version:     "2.3.1",
			Type:        "virtualmachine",
			Description: "Test Ubuntu 12.04 image (64 bit)",
			PublishedAt: "2014-01-20T16:12:31Z",
			Public:      true,
			State:       "active",
		},
		{
			Id:          "11223344-0a0a-ee88-22ab-00aa11bb22cc",
			Name:        "ubuntu12.10",
			OS:          "linux",
			Version:     "2.3.2",
			Type:        "virtualmachine",
			Description: "Test Ubuntu 12.10 image (64 bit)",
			PublishedAt: "2014-01-20T16:12:31Z",
			Public:      true,
			State:       "active",
		},
		{
			Id:          "11223344-0a0a-dd77-33cd-abcd1234e5f6",
			Name:        "ubuntu13.04",
			OS:          "linux",
			Version:     "2.2.8",
			Type:        "virtualmachine",
			Description: "Test Ubuntu 13.04 image (64 bit)",
			PublishedAt: "2014-01-20T16:12:31Z",
			Public:      true,
			State:       "active",
		},
	}
}

func generatePublicIPAddress() string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("32.151.%d.%d", r.Intn(255), r.Intn(255))
}

func generatePrivateIPAddress() string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("10.201.%d.%d", r.Intn(255), r.Intn(255))
}

func contains(list []string, elem string) bool {
	for _, t := range list {
		if t == elem {
			return true
		}
	}
	return false
}
