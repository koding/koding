package paymenterrors

import (
	"errors"
	"fmt"
	"strings"

	"github.com/jinzhu/gorm"
)

var (
	ErrPlanNotFound                    = errors.New("plan not found")
	ErrCustomerIdIsNotSet              = errors.New("customer id is not set")
	ErrCustomerNotFound                = errors.New("user not found")
	ErrCustomerAlreadySubscribedToPlan = errors.New("user is already subscribed to plan")
	ErrCustomerNotSubscribedToThatPlan = errors.New("user is not subscribed to that plan")
	ErrCustomerHasTooManySubscriptions = errors.New("user has too many subscriptions, should have only one")
	ErrCustomerNotSubscribedToAnyPlans = errors.New("user is not subscribed to any plans")
	ErrTokenIsEmpty                    = errors.New("token is required")
	ErrNoCreditCard                    = errors.New("no credit card")
	ErrAccountIdIsNotSet               = errors.New("account_id is not set")
	ErrGroupIdNotSet                   = errors.New("group_id is not set")

	ErrStripePlanAlreadyExists = errors.New(`{"type":"invalid_request_error","message":"Plan already exists."}`)

	// IsPlanNotFoundErr returns true if argument has part of pg error
	// messages matches. We do partial match since pg error message also
	// returns the dynamic enum value.
	IsPlanNotFoundErr = func(err error) bool {
		if err == nil {
			return false
		}

		if err == gorm.RecordNotFound {
			return true
		}

		return strings.Contains(
			err.Error(), "pq: invalid input value for enum payment.plan",
		)
	}

	// Customer probably has a coupon or credit in account and therefore
	// doesn't need to pay.
	IsNothingToInvoiceErr = func(err error) bool {
		if err == nil {
			return false
		}

		return err.Error() == "Nothing to invoice for customer"
	}

	ErrCustomerEmailIsEmpty = func(oldId string) error {
		return fmt.Errorf("customer: %s has no email", oldId)
	}

	ErrNotImplemented = errors.New("Requested action is not implemented for this provider.")
)
