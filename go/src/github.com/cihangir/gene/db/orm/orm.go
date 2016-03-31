package orm

import (
	"database/sql"

	"github.com/lann/squirrel"
)

type ORM struct {
	PlaceholderFormat squirrel.PlaceholderFormat
}

func New() *ORM {
	return &ORM{
		PlaceholderFormat: squirrel.Dollar,
	}
}

// Select(interface{}, interface{}, interface{}) error
// Create(interface{}, interface{}, interface{}) error
// Update(interface{}, interface{}, interface{}) error
// Delete(interface{}, interface{}, interface{}) error
// Some(interface{}, interface{}, interface{}) error
//
// Exec(query string, args ...interface{}) (sql.Result, error)
// Query(query string, args ...interface{}) (*sql.Rows, error)

type Tabler interface {
	TableName() string
}

type Selecter interface {
	Tabler
	SelectSQL() (string, []interface{}, error)
}

type Deleter interface {
	Tabler
	DeleteSQL() (string, []interface{}, error)
}

type Updater interface {
	Tabler
	UpdateSQL() (string, []interface{}, error)
}

type Inserter interface {
	Tabler
	InsertSQL() (string, []interface{}, error)
}

type RowsScanner interface {
	RowsScan(*sql.Rows, interface{})
}

type TablerRowsScanner interface {
	Tabler
	RowsScanner
}

// func (o *ORM) ByIds(a TablerRowsScanner, res interface{}, ids ...interface{}) error {
// 	sql, args, err := squirrel.
// 		StatementBuilder.
// 		PlaceholderFormat(o.PlaceholderFormat).
// 		Select("*").
// 		From(a.TableName()).
// 		// TODO(cihangir) may need to parameterize id
// 		Columns("id IN (" + squirrel.Placeholders(len(ids)) + ")").
// 		Values(ids...).
// 		ToSql()
// 	if err != nil {
// 		return err
// 	}

// 	rows, err := o.Query(sql, args)
// 	if err != nil {
// 		return err
// 	}

// 	return a.RowsScan(rows, res)
// }

// func (o *ORM) Select(a Selecter, res interface{}) error {
// 	sql, args, err := a.SelectSQL()
// 	if err != nil {
// 		return err
// 	}

// 	rows, err := o.Query(sql, args)
// 	if err != nil {
// 		return err
// 	}

// 	return a.RowsScan(rows, res)
// }

// func (o *ORM) Delete(a Deleter) error {
// 	sql, args, err := a.DeleteSQL()
// 	if err != nil {
// 		return err
// 	}

// 	_, err = o.Exec(sql, args)
// 	return err
// }

// func (o *ORM) Update(a Updater) error {
// 	query := squirrel.
// 		StatementBuilder.
// 		PlaceholderFormat(o.PlaceholderFormat).
// 		Update(a.TableName())

// 	sql, args, err := a.UpdateSQL(query).ToSql()
// 	if err != nil {
// 		return err
// 	}

// 	result, err := o.Exec(sql, args)
// 	if err != nil {
// 		return err
// 	}

// 	// TODO(cihangir) bind data into res
// 	return nil
// }

// func (o *ORM) Create(a Updater) error {
// 	query := squirrel.
// 		StatementBuilder.
// 		PlaceholderFormat(o.PlaceholderFormat).
// 		Insert(a.TableName())

// 	sql, args, err := a.CreateSQL(query).ToSql()
// 	if err != nil {
// 		return err
// 	}

// 	result, err := o.Exec(sql, args)
// 	if err != nil {
// 		return err
// 	}

// 	// TODO(cihangir) bind data into res
// 	return nil
// }
