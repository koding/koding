package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/jinzhu/gorm"
	_ "github.com/lib/pq"
)

var (
	user   = "socialapplication"
	dbName = "social"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Please pass pg host and url as seperate arguments.")
		os.Exit(1)
	}

	url, port := os.Args[1], os.Args[2]

	pgConfString := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		url, port, user, user, dbName,
	)

	db, err := gorm.Open("postgres", pgConfString)
	if err != nil {
		fmt.Println("Error connecting to db", err)
		return
	}

	db.DB()

	// uncomment this line to see sql queries, useful in debugging
	// db = *db.Debug()

	checkIfLocalIsUptodate(db)
}

func checkIfLocalIsUptodate(db gorm.DB) {
	var count int
	err := db.Table("payment.customer").Count(&count).Error

	if err == nil {
		return
	}

	if ErrConnRefusedFn(err) {
		fmt.Println(
			"Your postgresql isn't running/accessible, be run `./run services`.",
		)

		os.Exit(1)
	}

	if ErrPaymentTablesFn(err) {
		fmt.Println(
			"Your db doesn't have the latest schema, please do `./run buildservices`.",
		)

		os.Exit(1)
	}

	fmt.Println(
		"Your postgresql isn't running or your db doesn't have the latest schema, please do `./run buildservices`.",
	)

	os.Exit(1)
}

var ErrConnRefusedFn = func(err error) bool {
	return strings.Contains(err.Error(), "connection refused") || strings.Contains(err.Error(), "no such host")
}

var ErrPaymentTablesFn = func(err error) bool {
	return strings.Contains(err.Error(), "\"payment.customer\" does not exist")
}
