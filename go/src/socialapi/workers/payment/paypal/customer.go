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
		Provider:           PROVIDER_NAME,
		Username:           username,
	}

	err = customerModel.Create()

	return customerModel, err
}

func FindCustomerByOldId(oldId string) (*paymentmodels.Customer, error) {
	customerModel := paymentmodels.NewCustomer()
	err := customerModel.ByOldId(oldId)
	if err != nil {
		return nil, err
	}

	return customerModel, err
}
