package paymentmodels

import (
	"errors"
	"socialapi/workers/payment/paymenterrors"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Customer struct {
	Id int64 `json:"id,string"`

	OldId string `json:"oldId"`

	Username string `json:"username"`

	// Id of customer in 3rd payment provider like Stripe.
	ProviderCustomerId string `json:"providerCustomerId"`

	// Name of provider. Enum:
	//    'stripe', 'paypal'
	Provider string `json:"provider"`

	// Timestamps.
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" `
}

func (c *Customer) ByOldId(oldId string) error {
	selector := map[string]interface{}{"old_id": oldId}

	err := c.One(bongo.NewQS(selector))
	if err == gorm.RecordNotFound {
		return paymenterrors.ErrCustomerNotFound
	}

	return err
}

func (c *Customer) FindActiveSubscription() (*Subscription, error) {
	if c.Id == 0 {
		return nil, ErrIdNotSet
	}

	subscription := NewSubscription()
	err := subscription.ByCustomerIdAndState(c.Id, "active")

	return subscription, err
}

var ErrProviderCustomerIdIsSame = errors.New("provider customer id is the same")

func (c *Customer) UpdateProviderCustomerId(id string) error {
	if c.ProviderCustomerId == id {
		return ErrProviderCustomerIdIsSame
	}

	c.ProviderCustomerId = id

	return bongo.B.Update(c)
}

func (c *Customer) ByProviderCustomerId(id string) error {
	selector := map[string]interface{}{"provider_customer_id": id}

	err := c.One(bongo.NewQS(selector))
	if err == gorm.RecordNotFound {
		return paymenterrors.ErrCustomerNotFound
	}

	return err
}

func (c *Customer) FindSubscriptions() ([]Subscription, error) {
	if c.Id == 0 {
		return nil, ErrIdNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{"customer_id": c.Id},
		Sort:     map[string]string{"created_at": "DESC"},
	}

	var subscriptions = []Subscription{}

	s := Subscription{}
	err := s.Some(&subscriptions, query)
	if err != nil {
		return nil, err
	}

	return subscriptions, nil
}
