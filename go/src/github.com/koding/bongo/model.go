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

func (b *Bongo) CountWithQuery(i Modellable, q *Query) (int, error) {
	query := b.BuildQuery(i, q)
	var count int
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
	err := b.executeQuery(i, data, q)
	if err == gorm.RecordNotFound {
		return nil
	}
	return err
}

func (b *Bongo) One(i Modellable, data interface{}, q *Query) error {
	q.Pagination.Limit = 1
	return b.executeQuery(i, data, q)
}

func (b *Bongo) BuildQuery(i Modellable, q *Query) *gorm.DB {
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

	return query
}

func (b *Bongo) executeQuery(i Modellable, data interface{}, q *Query) error {
	// init query
	query := b.BuildQuery(i, q)

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

func (b *Bongo) PublishEvent(eventName string, i Modellable) error {
	data, err := json.Marshal(i)
	if err != nil {
		b.log.Error("Error while marshalling for publish %s", err)
		return err
	}

	err = b.Broker.Publish(i.TableName()+"_"+eventName, data)
	if err != nil {
		b.log.Error("Error while publishing %s", err)
		return err
	}

	return nil
}

func (b *Bongo) AfterCreate(i Modellable) {
	b.PublishEvent("created", i)
}

func (b *Bongo) AfterUpdate(i Modellable) {
	b.PublishEvent("updated", i)
}

func (b *Bongo) AfterDelete(i Modellable) {
	b.PublishEvent("deleted", i)
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

	// instead sending one selector, do chaining here
	return query.Where(selector)
}

func addSkip(query *gorm.DB, skip int) *gorm.DB {
	if skip > 0 {
		return query.Offset(skip)
	}

	return query
}

func addLimit(query *gorm.DB, limit int) *gorm.DB {
	// if limit is minus or 0 ignore
	if limit > 0 {
		return query.Limit(limit)
	}

	return query
}
