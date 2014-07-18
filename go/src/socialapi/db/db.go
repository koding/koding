package db

import (
	"fmt"
	"socialapi/config"

	"github.com/jinzhu/gorm"
	"github.com/koding/logging"
	_ "github.com/lib/pq"
)

// Gorm is goroutines friendly, so you can create a global variable
// to keep the connection and use it everywhere in your project
var DB *gorm.DB

func MustInit(conf *config.Config, log logging.Logger, debug bool) *gorm.DB {
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
		panic(fmt.Sprintf("Got error while connecting to database, the error is '%v'", err))
	}
	// By default, table name is plural of struct type, you can use struct type as table name with:
	db.SingularTable(true)

	// log queries if only in debug mode
	if debug {
		db.LogMode(true)
		db.SetLogger(NewGormLogger(log))
	}

	DB = &db
	return &db
}
