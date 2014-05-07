package bongo

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/jinzhu/gorm"
)

func (b *Bongo) Fetch(i Modellable) error {
	if i.GetId() == 0 {
		return errors.New(fmt.Sprintf("Id is not set for %s", i.TableName()))
	}

	if err := b.DB.Table(i.TableName()).
		Find(i).
		Error; err != nil {
		return err
	}

	return nil
}

func (b *Bongo) ById(i Modellable, id int64) error {
	if err := b.DB.
		Table(i.TableName()).
		Where("id = ?", id).
		Find(i).
		Error; err != nil {
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

	orderByQuery := ""
	comma := ""
	for _, id := range ids {
		orderByQuery = orderByQuery + comma + " id = " + strconv.FormatInt(id, 10) + " desc"
		comma = ","
	}
	return b.DB.
		Table(i.TableName()).
		Order(orderByQuery).
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
	Selector   map[string]interface{}
	Sort       map[string]string
	Pluck      string
	Pagination Pagination
}

type Pagination struct {
	Limit int
	Skip  int
}

func NewPagination(limit int, skip int) *Pagination {
	return &Pagination{
		Limit: limit,
		Skip:  skip,
	}
}

func NewQS(selector map[string]interface{}) *Query {
	return &Query{
		Selector: selector,
	}
}

// selector, sort, limit, pluck,
func (b *Bongo) Some(i Modellable, data interface{}, q *Query) error {
	err := b.buildQuery(i, data, q)
	if err == gorm.RecordNotFound {
		return nil
	}
	return err
}

func (b *Bongo) One(i Modellable, data interface{}, q *Query) error {
	q.Pagination.Limit = 1
	return b.buildQuery(i, data, q)
}

func (b *Bongo) buildQuery(i Modellable, data interface{}, q *Query) error {
	// init query
	query := b.DB

	// add table name
	query = query.Table(i.TableName())

	// add sort options
	query = addSort(query, q.Sort)

	query = addSkip(query, q.Pagination.Skip)

	query = addLimit(query, q.Pagination.Limit)

	// add selector
	query = addWhere(query, q.Selector)

	var err error
	// TODO refactor this part
	if q.Pluck != "" {
		if strings.Contains(q.Pluck, ",") {
			// add pluck data
			query = addPluck(query, q.Pluck)

			err = query.Find(data).Error
		} else {
			err = query.Pluck(q.Pluck, data).Error
		}
	} else {
		err = query.Find(data).Error
	}
	return err
}

func (b *Bongo) AfterCreate(i Modellable) {
	data, err := json.Marshal(i)
	if err != nil {
		return
	}

	err = b.Broker.Publish(i.TableName()+"_created", data)
	if err != nil {
		return
	}
}

func (b *Bongo) AfterUpdate(i Modellable) {
	data, err := json.Marshal(i)
	if err != nil {
		return
	}

	err = b.Broker.Publish(i.TableName()+"_updated", data)
	if err != nil {
		return
	}
}

func (b *Bongo) AfterDelete(i Modellable) {
	data, err := json.Marshal(i)
	if err != nil {
		return
	}

	err = b.Broker.Publish(i.TableName()+"_deleted", data)
	if err != nil {
		return
	}
}

func addSort(query *gorm.DB, options map[string]string) *gorm.DB {

	if options == nil {
		return query
	}

	if len(options) == 0 {
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

func addSkip(query *gorm.DB, skip int) *gorm.DB {
	if skip > 0 {
		return query.Offset(skip)
	}

	return query
}

func addLimit(query *gorm.DB, limit int) *gorm.DB {
	if limit > 0 {
		return query.Limit(limit)
	}

	return query
}
