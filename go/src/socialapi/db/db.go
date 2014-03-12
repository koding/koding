package db

import (
	"fmt"

	"github.com/jinzhu/gorm"
	_ "github.com/lib/pq"
)

// Gorm is goroutines friendly, so you can create a global variable
// to keep the connection and use it everywhere in your project
var DB gorm.DB

func init() {
	var err error
	DB, err = gorm.Open("postgres", "user=postgres password=123123123 dbname=social sslmode=disable")
	if err != nil {
		panic(fmt.Sprintf("Got error when connect database, the error is '%v'", err))
	}
	// By default, table name is plural of struct type, you can use struct type as table name with:
	DB.SingularTable(true)
	DB.LogMode(true)

}
