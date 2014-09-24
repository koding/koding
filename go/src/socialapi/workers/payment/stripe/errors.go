package stripe

import (
	"errors"
	"strings"
)

// TODO: move errors to own pkg
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

	ErrStripePlanAlreadyExists = errors.New(`{"type":"invalid_request_error","message":"Plan already exists."}`)

	// ErrPlanNotFoundFn returns true if argument has part of pg error
	// messages matches. We do partial match since pg error message also
	// returns the dynamic enum value.
	ErrPlanNotFoundFn = func(err error) bool {
		if err == nil {
			return false
		}

		return strings.Contains(
			err.Error(), "pq: invalid input value for enum payment.plan",
		)
	}
)
