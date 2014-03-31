package db

import (
	"fmt"
	"socialapi/config"

	"github.com/jinzhu/gorm"
	_ "github.com/lib/pq"
)

// Gorm is goroutines friendly, so you can create a global variable
// to keep the connection and use it everywhere in your project
var DB *gorm.DB

func MustInit(conf *config.Config) *gorm.DB {

	// host=localhost port=5432 dbname=mydb connect_timeout=10
	connString := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		conf.Postgres.Host,
		conf.Postgres.Port,
		conf.Postgres.Username,
		conf.Postgres.Password,
		conf.Postgres.DBName,
	)

	db, err := gorm.Open("postgres", connString)
	if err != nil {
		panic(fmt.Sprintf("Got error when connect database, the error is '%v'", err))
	}
	// By default, table name is plural of struct type, you can use struct type as table name with:
	db.SingularTable(true)
	db.LogMode(true)
	DB = &db
	return &db
}
