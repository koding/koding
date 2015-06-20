package ec2info

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"time"
)

const url = "http://169.254.169.254/latest/dynamic/instance-identity/document"

var DialTimeout = time.Second * 5

type EC2Info struct {
	InstanceID         string      `json:"instanceId"`
	BillingProducts    interface{} `json:"billingProducts"`
	ImageID            string      `json:"imageId"`
	Architecture       string      `json:"architecture"`
	PendingTime        time.Time   `json:"pendingTime"`
	InstanceType       string      `json:"instanceType"`
	AccountID          string      `json:"accountId"`
	KernelID           interface{} `json:"kernelId"`
	RamdiskID          interface{} `json:"ramdiskId"`
	Region             string      `json:"region"`
	Version            string      `json:"version"`
	AvailabilityZone   string      `json:"availabilityZone"`
	PrivateID          string      `json:"privateIp"`
	DevpayProductCodes interface{} `json:"devpayProductCodes"`
}

// Get returns EC2 metadata
func Get() (*EC2Info, error) {
	client := http.Client{
		Transport: &http.Transport{
			// timeout only for dialing, because if we are not in ec2, this will timeout
			Dial: func(network, addr string) (net.Conn, error) {
				return net.DialTimeout(network, addr, DialTimeout)
			},
		},
	}

	resp, err := client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		err = fmt.Errorf("Code %d returned for url %s", resp.StatusCode, url)
		return nil, err
	}

	identity := &EC2Info{}
	if err := json.NewDecoder(resp.Body).Decode(&identity); err != nil {
		return nil, err
	}

	return identity, nil
}
