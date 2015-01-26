package main

import "fmt"

func formatAmount(amount float64, currencyStr string) string {
	var currency string

	switch currencyStr {
	case "usd":
		currency = "$"
	default:
		Log.Error("Unknown currency: %v", currencyStr)
	}

	return fmt.Sprintf("%s %v", currency, amount/100)
}
