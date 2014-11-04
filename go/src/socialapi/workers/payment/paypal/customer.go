package paypal

import "socialapi/workers/payment/paymentmodels"

func CreateCustomer(accId, email string) (*paymentmodels.Customer, error) {
	// var username string

	// account, err := modelhelper.GetAccountById(accId)
	// if err == nil {
	//   username = account.Profile.Nickname
	// }

	// if err != nil {
	//   Log.Error("Fetching account: %s failed. %s", accId, err)
	// }

	customerModel := &paymentmodels.Customer{
		OldId:              accId,
		ProviderCustomerId: accId,
		Provider:           ProviderName,
		// Username:           username, // TODO: add username to migration
	}

	err := customerModel.Create()

	return customerModel, err
}

func FindCustomerByOldId(oldId string) (*paymentmodels.Customer, error) {
	customerModel := paymentmodels.NewCustomer()
	err := customerModel.ByOldId(oldId)

	return customerModel, err
}
