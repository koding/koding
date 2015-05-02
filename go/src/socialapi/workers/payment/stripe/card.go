package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"

	stripe "github.com/stripe/stripe-go"
	stripeCard "github.com/stripe/stripe-go/card"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

type CreditCardResponse struct {
	LastFour string `json:"last4"`
	Month    uint8  `json:"month"`
	Year     uint16 `json:"year"`
	Name     string `json:"name"`
	Brand    string `json:"brand"`
}

func GetCreditCard(oldId string) (*CreditCardResponse, error) {
	customer, err := paymentmodels.NewCustomer().ByOldId(oldId)
	if err != nil {
		return nil, err
	}

	externalCustomer, err := GetCustomer(customer.ProviderCustomerId)
	if err != nil {
		return nil, err
	}

	creditCardList := externalCustomer.Cards
	if IsNoCreditCards(creditCardList) {
		return &CreditCardResponse{}, nil
	}

	if IsTooManyCreditCards(creditCardList) {
		Log.Error(
			"Customer (stripe): %s has too many: %s credit cards.",
			customer.ProviderCustomerId, creditCardList.Count,
		)
	}

	creditCard := creditCardList.Values[0]
	creditCardResponse := &CreditCardResponse{
		LastFour: creditCard.LastFour,
		Month:    creditCard.Month,
		Year:     creditCard.Year,
		Name:     creditCard.Name,
		Brand:    string(creditCard.Brand),
	}

	return creditCardResponse, nil
}

func UpdateCreditCard(oldId, token string) error {
	if IsEmpty(token) {
		return paymenterrors.ErrTokenIsEmpty
	}

	customer, err := paymentmodels.NewCustomer().ByOldId(oldId)
	if err != nil {
		return err
	}

	customerParams := &stripe.CustomerParams{Token: token}

	_, err = stripeCustomer.Update(customer.ProviderCustomerId, customerParams)
	if err != nil {
		return handleStripeError(err)
	}

	return nil
}

func RemoveCreditCard(customer *paymentmodels.Customer) error {
	externalCustomer, err := GetCustomer(customer.ProviderCustomerId)
	if err != nil {
		return err
	}

	creditCardList := externalCustomer.Cards
	if IsNoCreditCards(creditCardList) {
		return paymenterrors.ErrNoCreditCard
	}

	if IsTooManyCreditCards(creditCardList) {
		Log.Error(
			"Customer (stripe): %s has too many: %s credit cards.",
			customer.ProviderCustomerId, creditCardList.Count,
		)
	}

	creditCard := creditCardList.Values[0]

	creditCardParams := &stripe.CardParams{
		Customer: externalCustomer.Id,
	}
	err = stripeCard.Del(creditCard.Id, creditCardParams)

	return err
}

func UpdateCreditCardIfEmpty(accId, token string) error {
	ccResp, err := GetCreditCard(accId)
	if err != nil {
		return err
	}

	if IsCreditCardEmpty(ccResp) {
		err := UpdateCreditCard(accId, token)
		if err != nil {
			return err
		}
	}

	return nil
}
