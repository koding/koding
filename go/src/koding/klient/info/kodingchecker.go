package info

import (
	"runtime"

	"koding/klient/fix"

	"github.com/koding/ec2dynamicdata"
)

const (
	// KodingAccountID is Koding's main AWS account ID
	KodingAccountID = "614068383889"

	// addRouteCommand and delRouteCommand are responsible for temporarily
	// disabling the aws api null route.
	addRouteCommand = "route add -host 169.254.169.254 reject"
	delRouteCommand = "route del -host 169.254.169.254 reject"
)

// TODO: Check the distro, if we're not on Ubuntu simply return false.
func CheckKoding() (bool, error) {
	_, isKoding, err := CheckKodingAWS()
	return isKoding, err
}

func CheckKodingAWS() (isAWS, isKoding bool, err error) {
	if cachedProviderName == Koding {
		return true, true, nil
	}

	// If we're not on Linux, we're not on a Koding VM
	if runtime.GOOS != "linux" {
		return false, false, nil
	}

	// Attempt to disable the aws api null route on Koding VMs.
	err = fix.RunAsSudo(delRouteCommand)
	// We expect delRoute to fail in many places (DO, localhost, etc),
	// but if it does not fail, we need to make sure to restore the null
	// route when this func is done.
	if err == nil {
		defer fix.RunAsSudo(addRouteCommand)
	}

	// Now try to get the data, if it's not available we can assume it's not
	// a Koding machine
	data, err := ec2dynamicdata.Get()

	// If there is an error requesting the API, there are two likely
	// scenarios:
	//
	// 1. We are not on a Koding AWS VM. Return false,nil
	// 2. The AWS API is being blocked / intercepted somehow. If this is
	// 		the case, we have no reliable way to determine if it is a
	// 		Koding VM - which means our only option is to return false,nil
	if err != nil {
		// Not returning the error, because this func is not actually
		// failing/erroring.
		return false, false, nil
	}

	// Check if the account ID is the same, if not, it belongs to
	// someone else (not Koding obviously)
	if data.AccountID != KodingAccountID {
		return true, false, nil
	}

	return true, true, nil
}
