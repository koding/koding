// Package db provides a simple interface for the db operations
package db

import (
	"database/sql"

	"github.com/lann/squirrel"
	"golang.org/x/net/context"
)

// DB holds the basic operation interfaces
type DB interface {
	ByIds(interface{}, interface{}, interface{}) error
	Select(interface{}, interface{}, interface{}) error
	Delete(interface{}, interface{}, interface{}) error
	Update(interface{}, interface{}, interface{}) error

	One(interface{}, interface{}, interface{}) error
	Create(interface{}, interface{}, interface{}) error
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
}

// DBKEY holds the key for the db value in net.Context
const DBKEY = "gene_db"

// MustGetDB returns the DB from context, if db not found with it's key, panics
func MustGetDB(ctx context.Context) DB {
	val := ctx.Value(DBKEY)
	if val == nil {
		panic("db is not set")
	}

	d, ok := val.(DB)
	if !ok {
		panic("db is not set")
	}

	return d
}

// SetDB sets the db into context and returns the modified context
func SetDB(ctx context.Context, d DB) context.Context {
	return context.WithValue(ctx, DBKEY, d)
}

// func UpdateBuilder(ctx context.Context, a Tabler) (squirrel.UpdateBuilder, error) {

// }

type Builder int

const (
	Insert Builder = 1 << iota
	Select
	Delete
	Update
)

func MustGetInsertBuilder(ctx context.Context) squirrel.InsertBuilder {
	insertBuilder, ok := ctx.Value(Insert).(squirrel.InsertBuilder)
	if !ok {
		panic("doesnt have InsertBuilder")
	}

	return insertBuilder
}
