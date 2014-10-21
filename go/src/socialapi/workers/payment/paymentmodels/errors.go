package paymentmodels

import "errors"

//----------------------------------------------------------
// Plan
//----------------------------------------------------------

var (
	ErrTitleNotSet    = errors.New("title not set")
	ErrIntervalNotSet = errors.New("interval not set")
)

//----------------------------------------------------------
// Customer
//----------------------------------------------------------

var (
	ErrOldIdNotSet = errors.New("old_id not set")
	ErrIdNotSet    = errors.New("id not set")
)

//----------------------------------------------------------
// Subscription
//----------------------------------------------------------

var (
	ErrProviderSubscriptionIdNotSet = errors.New("provider_subscription_id is not set")
	ErrProviderNotSet               = errors.New("provider is not set")
	ErrIdNotset                     = errors.New("id is not set")
	ErrUpdatingToSamePlan           = errors.New("subscription already subscribed to that plan")
)
