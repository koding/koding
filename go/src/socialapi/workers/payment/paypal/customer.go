package paypal

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/payment/paymentmodels"
)

func CreateCustomer(accId string) (*paymentmodels.Customer, error) {
	var username string

	account, err := modelhelper.GetAccountById(accId)
	if err == nil {
		username = account.Profile.Nickname
	}

	if err != nil {
		Log.Error("Fetching account: %s failed. %s", accId, err)
	}

	customerModel := &paymentmodels.Customer{
		OldId:              accId,
		ProviderCustomerId: accId,
		Provider:           ProviderName,
		Username:           username,
		Type:               paymentmodels.AccountCustomer,
	}

	err = customerModel.Create()

	return customerModel, err
}
