package main

import (
	"fmt"
	"socialapi/models"
)

func testAccountOperations() {

	for i := 0; i < 2; i++ {
		a := models.NewAccount()
		a.OldId = "ASdfasdf"
		acc, err := createAccount(a)
		if err != nil {
			fmt.Println("err while creating account", err)
			return
		}
		fmt.Print(acc)
	}

}

func createAccount(a *models.Account) (*models.Account, error) {
	acc, err := sendModel("POST", "/account", a)
	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}
