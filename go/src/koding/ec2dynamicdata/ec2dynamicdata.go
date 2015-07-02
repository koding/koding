// Package ec2dynamicdata gets ec2 dynamic data  or meta data for the current
// running ec2 host
package ec2dynamicdata

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"time"
)

const endpoint = "http://169.254.169.254/latest/dynamic/instance-identity/document"

var (
	// DialTimeout holds timeout value for ec2 dynamic data calls
	DialTimeout = time.Second * 5
)

// Err wraps any possible errors for api call
type Err struct {
	Err      error
	Original error
}

// Error implements the error interface.
func (e *Err) Error() string {
	return e.Err.Error()
}

// Data holds dynamic data about current ec2 host
type Data struct {
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

// Get returns EC2 dynamic data
func Get() (*Data, error) {
	client := http.Client{
		Transport: &http.Transport{
			// timeout only for dialing, because if we are not in ec2, this will timeout
			Dial: func(network, addr string) (net.Conn, error) {
				return net.DialTimeout(network, addr, DialTimeout)
			},
		},
	}

	resp, err := client.Get(endpoint)
	if err != nil {
		return nil, wrapEC2Error(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("err: status code (%d)", resp.StatusCode)
	}

	identity := &Data{}
	if err := json.NewDecoder(resp.Body).Decode(&identity); err != nil {
		return nil, err
	}

	return identity, nil
}

func wrapEC2Error(err error) error {
	if uerr, ok := err.(*url.Error); ok {
		if _, ok := uerr.Err.(*net.OpError); ok {
			return &Err{Original: err, Err: errors.New("not an ec2 instance")}
		}
	}

	return err
}
