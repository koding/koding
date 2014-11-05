package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
)

type status int

const (
	Default                 status = iota
	AlreadySubscribedToPlan status = iota
	NewSubscription         status = iota
	DowngradeToFreePlan     status = iota
	Downgrade               status = iota
	Upgrade                 status = iota
)

func checkStatus(customer *paymentmodels.Customer, err error, plan *paymentmodels.Plan) status {
	if IsNewSubscription(customer, err) {
		return NewSubscription
	}

	return Default
}

func IsNewSubscription(customer *paymentmodels.Customer, err error) bool {
	if customer == nil && err == paymenterrors.ErrCustomerNotFound {
		return true
	}

	return false
}

func IsSubscribedToPlan(customer *paymentmodels.Customer, plan *paymentmodels.Plan) bool {
	return false
}

func IsDowngradeToFreePlan(customer *paymentmodels.Customer, plan *paymentmodels.Plan) bool {
	return false
}

func IsDowngrade(customer *paymentmodels.Customer, plan *paymentmodels.Plan) bool {
	return false
}

func IsUgrade(customer *paymentmodels.Customer, plan *paymentmodels.Plan) bool {
	return false
}
