package runner

import (
	"fmt"
	"regexp"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/logging"
	_ "github.com/lib/pq"
)

// Gorm is goroutines friendly, so you can create a global variable
// to keep the connection and use it everywhere in your project
var DB *gorm.DB

func MustInitDB(conf *Config, log logging.Logger, debug bool) *gorm.DB {
	connString := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
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
	db.DB().SetMaxOpenConns(50)
	db.SetLogger(NewGormLogger(log))

	// log queries if only in debug mode
	if debug {
		db.LogMode(true)
	}

	DB = &db
	return &db
}

func NewGormLogger(log logging.Logger) *gormLogger {
	return &gormLogger{log: log}
}

// custom logger for gorm
type gormLogger struct {
	log logging.Logger
}

// Format log
var sqlRegexp = regexp.MustCompile(`(\$\d+)|\?`)

// implement gorm logging interface
func (g *gormLogger) Print(v ...interface{}) {
	messages := []interface{}{}

	// taken from gorm log file
	if len(v) > 4 {
		messages = append(messages, fmt.Sprintf("[%.2fms] ", float64(v[2].(time.Duration).Nanoseconds()/1e4)/100.0))
		messages = append(messages, fmt.Sprintf(sqlRegexp.ReplaceAllString(v[3].(string), "'%v'"), v[4].([]interface{})...))
	} else {
		for _, message := range v {
			messages = append(messages, fmt.Sprintf("%s", message))
		}
	}

	format := ""
	for i := 0; i < len(messages); i++ {
		format += "%s"
	}

	g.log.Debug(format, messages...)
}
