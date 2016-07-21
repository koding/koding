package ec2dynamicdata

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
)

const metaDataEndpoint = "http://169.254.169.254/latest/meta-data/"

// Item defines a single resource that can be retrieved from a met-data
// endpoint
type Item int

// This is an incomplete list because other items have sub items. So if you
// need them just modify the source to have a support to it. But probably it's
// an overkill and you'll not going to need it :)
const (
	AmiId Item = iota + 1
	AmiLaunchIndex
	AmiManifestPath
	Hostname
	InstanceAction
	InstanceId
	InstanceType
	LocalHostname
	LocalIPv4
	Mac
	Profile
	PublicIPv4
	PublicHostname
	ReservationId
	SecurityGroups
)

// String implements the Stringer interface. It's also used to construct the
// meta-data endpoint
func (i Item) String() string {
	switch i {
	case AmiId:
		return "ami-id"
	case AmiLaunchIndex:
		return "ami-launch-index"
	case AmiManifestPath:
		return "ami-manifest-path"
	case Hostname:
		return "hostname"
	case InstanceAction:
		return "instance-action"
	case InstanceId:
		return "instance-id"
	case InstanceType:
		return "instance-type"
	case LocalHostname:
		return "local-hostname"
	case LocalIPv4:
		return "local-ipv4"
	case Mac:
		return "mac"
	case Profile:
		return "profile"
	case PublicIPv4:
		return "public-ipv4"
	case PublicHostname:
		return "public-hostname"
	case ReservationId:
		return "reservation-id"
	case SecurityGroups:
		return "security-groups"
	default:
		return "unknown"
	}
}

// GetMetadata returns the value for the given meta data item.
func GetMetadata(item Item) (string, error) {
	client := http.Client{
		Transport: &http.Transport{
			// timeout only for dialing, because if we are not in ec2, this will timeout
			Dial: func(network, addr string) (net.Conn, error) {
				return net.DialTimeout(network, addr, DialTimeout)
			},
		},
	}

	resp, err := client.Get(metaDataEndpoint + item.String())
	if err != nil {
		return "", wrapEC2Error(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("err: status code (%d)", resp.StatusCode)
	}

	out, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(out), nil
}
