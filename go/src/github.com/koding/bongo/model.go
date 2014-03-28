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

	if err := b.DB.First(i.Self(), i.GetId()).Error; err != nil {
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

	return b.Create(i)
}

// selector, set
func (b *Bongo) UpdatePartial(i Modellable, rest ...map[string]interface{}) error {
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

	if i.GetId() != 0 {
		query = query.Where(i.GetId())
	} else {
		//add selector
		query = addWhere(query, selector)
	}

	if err := query.Model(i.Self()).Update(set).Error; err != nil {
		return err
	}

	return nil
}

func (b *Bongo) Delete(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := b.DB.Delete(i.Self()).Error; err != nil {
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

func (b *Bongo) Some(i Modellable, data interface{}, rest ...map[string]interface{}) error {

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
	query := b.DB

	// add pluck data
	query = addPluck(query, plucked)

	// add sort options
	query = addSort(query, options)

	// add table name
	query = query.Table(i.TableName())

	// add selector
	query = addWhere(query, selector)
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
	data, err := json.Marshal(i.Self())
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
	data, err := json.Marshal(i.Self())
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
	data, err := json.Marshal(i.Self())
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
