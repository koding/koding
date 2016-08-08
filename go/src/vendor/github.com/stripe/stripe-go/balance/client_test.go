package balance

import (
	"testing"

	. "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/charge"
	. "github.com/stripe/stripe-go/utils"
)

func init() {
	Key = GetTestKey()
}

func TestBalanceGet(t *testing.T) {
	target, err := Get(nil)

	if err != nil {
		t.Error(err)
	}

	if target.Available == nil || len(target.Available) != 1 {
		t.Errorf("Available array is not set\n")
	}

	if target.Pending == nil || len(target.Pending) != 1 {
		t.Errorf("Pending array is not set\n")
	}

	if len(target.Available[0].Currency) == 0 {
		t.Errorf("Available currency is not set\n")
	}

	if len(target.Pending[0].Currency) == 0 {
		t.Errorf("Pending currency is not set\n")
	}
}

func TestBalanceGetTx(t *testing.T) {
	chargeParams := &ChargeParams{
		Amount:   1002,
		Currency: USD,
		Card: &CardParams{
			Number: "378282246310005",
			Month:  "06",
			Year:   "20",
		},
		Desc: "charge transaction",
	}

	res, _ := charge.New(chargeParams)

	target, err := GetTx(res.Tx.Id, nil)

	if err != nil {
		t.Error(err)
	}

	if uint64(target.Amount) != chargeParams.Amount {
		t.Errorf("Amount %v does not match expected amount %v\n", target.Amount, chargeParams.Amount)
	}

	if target.Currency != chargeParams.Currency {
		t.Errorf("Currency %q does not match expected currency %q\n", target.Currency, chargeParams.Currency)
	}

	if target.Desc != chargeParams.Desc {
		t.Errorf("Description %q does not match expected description %q\n", target.Desc, chargeParams.Desc)
	}

	if target.Available == 0 {
		t.Errorf("Available date is not set\n")
	}

	if target.Created == 0 {
		t.Errorf("Created date is not set\n")
	}

	if target.Fee == 0 {
		t.Errorf("Fee is not set\n")
	}

	if target.FeeDetails == nil || len(target.FeeDetails) != 1 {
		t.Errorf("Fee details are not set")
	}

	if target.FeeDetails[0].Amount == 0 {
		t.Errorf("Fee detail amount is not set\n")
	}

	if len(target.FeeDetails[0].Currency) == 0 {
		t.Errorf("Fee detail currency is not set\n")
	}

	if len(target.FeeDetails[0].Desc) == 0 {
		t.Errorf("Fee detail description is not set\n")
	}

	if target.Net == 0 {
		t.Errorf("Net is not set\n")
	}

	if target.Status != TxPending {
		t.Errorf("Status %v does not match expected value\n", target.Status)
	}

	if target.Type != TxCharge {
		t.Errorf("Type %v does not match expected value\n", target.Type)
	}

	if target.Src != res.Id {
		t.Errorf("Source %q does not match expeted value %q\n", target.Src, res.Id)
	}
}

func TestBalanceList(t *testing.T) {
	params := &TxListParams{}
	params.Filters.AddFilter("limit", "", "5")
	params.Single = true

	i := List(params)
	for !i.Stop() {
		target, err := i.Next()

		if err != nil {
			t.Error(err)
		}

		if target == nil {
			t.Error("No nil values expected")
		}

		if i.Meta() == nil {
			t.Error("No metadata returned")
		}
	}
}
