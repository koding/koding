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
		Log.Error(err.Error())
	}

	return formatAmount(currencyStr, amount)
}

func formatAmount(currency string, amount float64) string {
	switch currency {
	case "USD", "usd":
		currency = "$"
	default:
		Log.Error("Unknown currency: %v", currency)
	}

	return fmt.Sprintf("%s%v", currency, amount)
}
