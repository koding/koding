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

func (m Model) FetchByIds(i Modellable, data interface{}, ids []int64) error {
	if len(ids) == 0 {
		return nil
	}

	return db.DB.
		Table(i.TableName()).
		Where(ids).
		Find(data).
		Error

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
		query = addWhere(query, selector)
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

func (m Model) Count(i Modellable, where ...interface{}) (int, error) {
	var count int

	// init query
	query := db.DB

	// add table name
	query = query.Table(i.TableName())

	// add query
	query = query.Where(where[0], where[1:len(where)]...)

	return count, query.Count(&count).Error
}

func (m Model) Some(i Modellable, data interface{}, rest ...map[string]interface{}) error {

	var selector, options, plucked map[string]interface{}
	switch len(rest) {

	case 1: // just filter
		selector = rest[0]
	case 2: //filter and sort
		selector = rest[0]
		options = rest[1]
	case 3: // filter, sort and only get some data of the result set
		selector = rest[0]
		options = rest[1]
		plucked = rest[2]
	default:
		return errors.New("Some parameter list is wrong")
	}

	// init query
	query := db.DB

	// add pluck data
	query = addPluck(query, plucked)

	// add sort options
	query = addSort(query, options)

	// add table name
	query = query.Table(i.TableName())

	// add selector
	query = addWhere(query, selector)
	return query.Find(data).Error
}

func addSort(query *gorm.DB, options map[string]interface{}) *gorm.DB {

	if options == nil {
		return query
	}

	var opts []string
	for key, val := range options {
		opts = append(opts, fmt.Sprintf("%s %v", key, val))
	}
	return query.Order(strings.Join(opts, ","))
}

func addPluck(query *gorm.DB, plucked map[string]interface{}) *gorm.DB {

	if plucked == nil {
		return query
	}

	var opts []string
	for key := range plucked {
		opts = append(opts, fmt.Sprintf("%s", key))
	}
	fmt.Println(strings.Join(opts, ","))
	return query.Select(strings.Join(opts, ","))
}

func addWhere(query *gorm.DB, selector map[string]interface{}) *gorm.DB {
	if selector == nil {
		return query
	}
	return query.Where(selector)
}
