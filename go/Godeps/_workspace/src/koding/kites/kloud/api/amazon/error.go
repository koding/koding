package amazon

import (
	"errors"
	"fmt"

	"github.com/aws/aws-sdk-go/aws/awserr"
)

var (
	ErrInstanceTerminated = errors.New("instance is terminated")
	ErrInstanceEmptyID    = errors.New("instance ID is empty")
	ErrNoInstances        = errors.New("no instances found")
)

// OrigErr returns (unboxes) the underlying reason for the error.
//
// If err was not boxed and/or is not a specialised error, the function
// is effectively a nop.
func OrigErr(err error) error {
	switch e := err.(type) {
	case *NotFoundError:
		return e.Err
	case awserr.Error:
		return e.OrigErr()
	default:
		return err
	}
}

// EqualErr returns true when both errors are equal or underlying error for
// both of them are equal.
func EqualErr(lhs, rhs error) bool {
	return OrigErr(lhs) == OrigErr(rhs)
}

// IsErrCode returns true if err is of awserr.Error type and its code
// is one of the given codes; otherwise it returns false.
//
// For the list of possible error codes see:
//
//   https://docs.aws.amazon.com/AWSEC2/latest/APIReference/errors-overview.html
//
func IsErrCode(err error, codes ...string) bool {
	e, ok := err.(awserr.Error)
	if !ok {
		return false
	}
	for _, code := range codes {
		if e.Code() == code {
			return true
		}
	}
	return false
}

// NotFoundError is a special kind of error returned by the Client wrapper.
// This error may occur because the recently created resource has not
// propagated through the system.
//
// For more details see:
//
//   https://docs.aws.amazon.com/AWSEC2/latest/APIReference/query-api-troubleshooting.html#eventual-consistency
//
type NotFoundError struct {
	Resource string // resource type that was requested
	Err      error  // underlying reason that caused the error
}

// Error implements the builtin error interface.
func (err *NotFoundError) Error() string {
	return fmt.Sprintf("%s not found: %s", err.Resource, err.Err)
}

// IsNotFound returns true if the given error is of *NotFoundError type.
func IsNotFound(err error) bool {
	_, ok := err.(*NotFoundError)
	return ok
}

func newNotFoundError(res string, err error) error {
	return &NotFoundError{
		Resource: res,
		Err:      err,
	}
}

// awsError wraps the given awserr.Error with:
//
//   - *NotFoundError, if the given error has one of the *.NotFound error codes
//
// Otherwise or if the err was nil the function is a nop.
func awsError(err error) error {
	e, ok := err.(awserr.Error)
	if !ok || err == nil {
		return err
	}
	// Based on: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/errors-overview.html
	//
	// Not all error codes are listed as we don't use all AWS API calls.
	switch e.Code() {
	case "InvalidAddress.NotFound":
		return newNotFoundError("Address", err)
	case "InvalidAMIID.NotFound":
		return newNotFoundError("Image", err)
	case "InvalidGroup.NotFound":
		return newNotFoundError("SecurityGroup", err)
	case "InvalidInstanceID.NotFound":
		return newNotFoundError("Instance", err)
	case "InvalidKeyPair.NotFound":
		return newNotFoundError("KeyPair", err)
	case "InvalidSecurityGroupID.NotFound":
		return newNotFoundError("SecurityGroup", err)
	case "InvalidSnapshot.NotFound":
		return newNotFoundError("Snapshot", err)
	case "InvalidSubnetID.NotFound":
		return newNotFoundError("Subnet", err)
	case "InvalidVolume.NotFound":
		return newNotFoundError("Volume", err)
	case "InvalidVpcEndpointId.NotFound":
		return newNotFoundError("VPCEndpoint", err)
	case "InvalidVpcID.NotFound":
		return newNotFoundError("VPC", err)
	case "InvalidZone.NotFound":
		return newNotFoundError("Zone", err)
	default:
		return err
	}
}
