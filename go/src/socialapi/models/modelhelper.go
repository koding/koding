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
	if err := db.DB.Save(i).Error; err != nil {
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

// selector, set
func (m Model) UpdatePartial(i Modellable, rest ...map[string]interface{}) error {
	var set, selector map[string]interface{}

	switch len(rest) {
	case 1:
		set = rest[0]
		selector = nil
	case 2:
		selector = rest[0]
		set = rest[1]
	default:
		return errors.New("Update partial parameter list is wrong")
	}

	query := db.DB.Table(i.TableName())

	if i.GetId() != 0 {
		query = query.Where(i.GetId())
	} else {
		//add selector
		query = getWhere(query, selector)
	}

	if err := query.Update(set).Error; err != nil {
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

func (m Model) Some(i Modellable, data interface{}, rest ...map[string]interface{}) error {

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

func getSort(query *gorm.DB, options map[string]interface{}) *gorm.DB {

	if options == nil {
		return query
	}

	var opts []string
	for key, val := range options {
		opts = append(opts, fmt.Sprintf("%s %v", key, val))
	}
	return query.Order(strings.Join(opts, ","))
}

func getWhere(query *gorm.DB, selector map[string]interface{}) *gorm.DB {
	if selector == nil {
		return query
	}
	return query.Where(selector)
}
