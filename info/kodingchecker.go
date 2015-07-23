package info

import (
	"errors"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/ec2dynamicdata"
)

// KodingAccountID is Koding's main AWS account ID
const KodingAccountID = "614068383889"

func CheckKoding() (bool, error) {
	// First try to get the data, if it's not available we can assume it's not
	// a Koding machine
	data, err := ec2dynamicdata.Get()
	// TODO: Parse this error type and do not return it if it's a 404
	if err != nil {
		return true, err
	}

	// Second check if the account ID is the same, if not, it belongs to
	// someone else (not Koding obviously)
	if data.AccountID == KodingAccountID {
		return true, nil
	}

	return false, errors.New("account ID doesn not match Koding's account ID")
}
