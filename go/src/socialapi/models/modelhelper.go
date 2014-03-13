package models

import (
	"errors"
	"fmt"
	"socialapi/db"
	"strings"

	"github.com/jinzhu/gorm"
)

type Partial map[string]interface{}

type Modellable interface {
	// Id int64
	GetId() int64
	TableName() string
	Self() Modellable
}

type Model struct{}

func (m Model) Fetch(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := db.DB.First(i.Self(), i.GetId()).Error; err != nil {
		return err
	}

	return nil
}

func (m Model) Create(i Modellable) error {
	if err := db.DB.Save(i.Self()).Error; err != nil {
		return err
	}

	return nil
}

func (m Model) Update(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	return m.Create(i)
}

func (m Model) UpdatePartial(i Modellable, partial Partial) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := db.DB.
		Table(i.TableName()).
		Where(i.GetId()).
		Update(partial).
		Error; err != nil {
		return err
	}

	return nil
}

func (m Model) Delete(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := db.DB.Delete(i.Self()).Error; err != nil {
		return err
	}

	return nil
}

func (m Model) Some(i Modellable, data interface{}, rest ...Partial) error {

	var selector Partial
	var options Partial

	if length := len(rest); length > 0 {
		selector = rest[0]
		if length == 2 {
			options = rest[1]
		}
	}

	// init query
	query := db.DB

	// add sort options
	query = getSort(query, options)

	// add table name
	query = query.Table(i.TableName())

	// add selector
	query = getWhere(query, selector)

	return query.Find(data).Error
}

func getSort(query *gorm.DB, options Partial) *gorm.DB {

	if options == nil {
		return query
	}

	var opts []string
	for key, val := range options {
		opts = append(opts, fmt.Sprintf("%s %s", key, val))
	}
	return query.Order(strings.Join(opts, ","))
}

func getWhere(query *gorm.DB, selector Partial) *gorm.DB {
	if selector == nil {
		return query
	}
	return query.Where(selector)
}

func Save(d interface{}) error {
	return db.DB.Save(d).Error
}

func Delete(d interface{}) error {
	return db.DB.Delete(d).Error
}

func First(d interface{}, id int64) error {
	return db.DB.First(d, id).Error
}
