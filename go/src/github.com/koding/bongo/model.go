package bongo

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/jinzhu/gorm"
)

func (b *Bongo) Fetch(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := b.DB.First(i, i.GetId()).Error; err != nil {
		return err
	}

	return nil
}

func (b *Bongo) Create(i Modellable) error {
	if err := b.DB.Save(i).Error; err != nil {
		return err
	}

	return nil
}

func (b *Bongo) Update(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	// Update and Create is using the Save method, so they are
	// same functions but GORM handles, AfterCreate and AfterUpdate
	// in correct manner
	return b.Create(i)
}

func (b *Bongo) Delete(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := b.DB.Delete(i).Error; err != nil {
		return err
	}

	return nil
}

func (b *Bongo) FetchByIds(i Modellable, data interface{}, ids []int64) error {
	if len(ids) == 0 {
		return nil
	}

	return b.DB.
		Table(i.TableName()).
		Where(ids).
		Find(data).
		Error

}

func (b *Bongo) UpdatePartial(i Modellable, set map[string]interface{}) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	query := b.DB.Table(i.TableName())

	query = query.Where(i.GetId())

	if err := query.Update(set).Error; err != nil {
		return err
	}

	if err := b.Fetch(i); err != nil {
		return err
	}

	b.AfterUpdate(i)
	return nil
}

// selector, set
func (b *Bongo) UpdateMulti(i Modellable, rest ...map[string]interface{}) error {
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

	query := b.DB.Table(i.TableName())

	//add selector
	query = addWhere(query, selector)

	if err := query.Update(set).Error; err != nil {
		return err
	}

	return nil
}

func (b *Bongo) Count(i Modellable, where ...interface{}) (int, error) {
	var count int

	// init query
	query := b.DB

	// add table name
	query = query.Table(i.TableName())

	// add query
	query = query.Where(where[0], where[1:len(where)]...)

	return count, query.Count(&count).Error
}

type Query struct {
	Selector map[string]interface{}
	Sort     map[string]string
	Limit    int
	Pluck    string
}

// selector, sort, limit, pluck,
func (b *Bongo) Some(i Modellable, data interface{}, q *Query) error {

	// init query
	query := b.DB

	// add pluck data
	query = addPluck(query, q.Pluck)

	// add sort options
	query = addSort(query, q.Sort)

	// add table name
	query = query.Table(i.TableName())

	// add selector
	query = addWhere(query, q.Selector)

	err := query.Find(data).Error
	if err == gorm.RecordNotFound {
		return nil
	}
	return err
}

func (b *Bongo) One(i Modellable, data interface{}, selector map[string]interface{}) error {

	// init query
	query := b.DB

	// add table name
	query = query.Table(i.TableName())

	// add selector
	query = addWhere(query, selector)

	// add limit
	query.Limit(1)

	return query.Find(data).Error
}

func (b *Bongo) AfterCreate(i Modellable) {
	eventName := fmt.Sprintf("%s_created", i.TableName())
	data, err := json.Marshal(i)
	if err != nil {
		// here try to resend this message to RMQ again, than
		// persist it to somewhere!#!##@$%#?
		// those messages are really important now
		fmt.Println("Error occured", err)
		return
	}
	err = b.Broker.Publish(eventName, data)
	if err != nil {
		fmt.Println("jhasdjhadsjdasj", err)
	}
}

func (b *Bongo) AfterUpdate(i Modellable) {
	eventName := fmt.Sprintf("%s_updated", i.TableName())
	data, err := json.Marshal(i)
	if err != nil {
		// here try to resend this message to RMQ again, than
		// persist it to somewhere!#!##@$%#?
		// those messages are really important now
		fmt.Println("Error occured", err)
		return
	}
	err = b.Broker.Publish(eventName, data)
	if err != nil {
		fmt.Println("jhasdjhadsjdasj", err)
	}
}

func (b *Bongo) AfterDelete(i Modellable) {
	eventName := fmt.Sprintf("%s_deleted", i.TableName())
	data, err := json.Marshal(i)
	if err != nil {
		// here try to resend this message to RMQ again, than
		// persist it to somewhere!#!##@$%#?
		// those messages are really important now
		fmt.Println("Error occured", err)
		return
	}
	err = b.Broker.Publish(eventName, data)
	if err != nil {
		fmt.Println("jhasdjhadsjdasj", err)
	}
}

func addSort(query *gorm.DB, options map[string]string) *gorm.DB {

	if options == nil {
		return query
	}

	var opts []string
	for key, val := range options {
		opts = append(opts, fmt.Sprintf("%s %v", key, val))
	}
	return query.Order(strings.Join(opts, ","))
}

func addPluck(query *gorm.DB, plucked string) *gorm.DB {
	if plucked == "" {
		return query
	}

	return query.Select(plucked)
}

func addWhere(query *gorm.DB, selector map[string]interface{}) *gorm.DB {
	if selector == nil {
		return query
	}
	return query.Where(selector)
}
