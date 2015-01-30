package main

import (
	"fmt"
	"strconv"
)

func formatStripeAmount(currencyStr string, amount float64) string {
	return formatAmount(currencyStr, amount/100)
}

func formatPaypalAmount(currencyStr, amountStr string) string {
	amount, err := strconv.ParseFloat(amountStr, 64)
	if err != nil {
		Log.Error("Paypal: error converting amount: %v to float: %s", amountStr, err.Error())
	}

	return formatAmount(currencyStr, amount)
}

func formatAmount(currency string, amount float64) string {
	switch currency {
	case "USD", "usd":
		currency = "$"
	default:
		Log.Error("Paypal: unknown currency: %v, amount: %v", currency, amount)
	}

	return fmt.Sprintf("%s%v", currency, amount)
}
