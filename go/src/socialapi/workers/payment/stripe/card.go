package stripe

import (
	"socialapi/models/paymentmodel"

	stripe "github.com/stripe/stripe-go"
	stripeCard "github.com/stripe/stripe-go/card"
	stripeCustomer "github.com/stripe/stripe-go/customer"
)

type CreditCardResponse struct {
	LastFour string `json:"last4"`
	Month    uint8  `json:"month"`
	Year     uint16 `json:"year"`
	Name     string `json:"name"`
}

func GetCreditCard(oldId string) (*CreditCardResponse, error) {
	customer, err := FindCustomerByOldId(oldId)
	if err != nil {
		return nil, err
	}

	externalCustomer, err := GetCustomerFromStripe(customer.ProviderCustomerId)
	if err != nil {
		return nil, err
	}

	creditCardList := externalCustomer.Cards
	if IsNoCreditCards(creditCardList) {
		return &CreditCardResponse{}, nil
	}

	if IsTooManyCreditCards(creditCardList) {
		//TODO: how to handle too many ccs?
	}

	creditCard := creditCardList.Values[0]
	creditCardResponse := &CreditCardResponse{
		LastFour: creditCard.LastFour,
		Month:    creditCard.Month,
		Year:     creditCard.Year,
		Name:     creditCard.Name,
	}

	return creditCardResponse, nil
}

func UpdateCreditCard(oldId, token string) error {
	customer, err := FindCustomerByOldId(oldId)
	if err != nil {
		return err
	}

	customerParams := &stripe.CustomerParams{Token: token}

	_, err = stripeCustomer.Update(customer.ProviderCustomerId, customerParams)
	if err != nil {
		return err
	}

	return nil
}

func RemoveCreditCard(customer *paymentmodel.Customer) error {
	externalCustomer, err := GetCustomerFromStripe(customer.ProviderCustomerId)
	if err != nil {
		return err
	}

	creditCardList := externalCustomer.Cards
	if IsNoCreditCards(creditCardList) {
		return ErrNoCreditCard
	}

	if IsTooManyCreditCards(creditCardList) {
		//TODO: how to handle too many ccs?
	}

	creditCard := creditCardList.Values[0]

	creditCardParams := &stripe.CardParams{
		Customer: externalCustomer.Id,
	}
	err = stripeCard.Del(creditCard.Id, creditCardParams)
	if err != nil {
		return err
	}

	return nil
}
