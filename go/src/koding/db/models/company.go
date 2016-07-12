package models

import (
	"errors"
	"strings"

	"gopkg.in/mgo.v2/bson"
)

type Company struct {
	Id bson.ObjectId `bson:"_id" json:"_id"`
	// Name holds the name of the company,
	// Company name is case sensitive, so use slug instead of Name for company operations
	// e.g : Koding, PubNub ...
	Name string `bson:"name" json:"name"`
	// Slug is the LowerCase format of the company name
	// this satify us consistency on company operations
	// e.g : koding, pubnub ...
	Slug string `bson:"slug" json:"slug"`
	// Employees holds the employee count of the companies
	// e.g: koding members; 20
	Employees int `bson:"employees" json:"employees"`
	// Domain is the domain of the company
	// e.g: koding.com
	Domain string `bson:"domain" json:"domain"`
}

// Error values for returning values
var (
	ErrCompanyNameIsEmpty   = errors.New("company name is empty")
	ErrCompanyEmployeesZero = errors.New("company employees is zero")
)

func (c *Company) CheckValues() error {
	if c.Name == "" {
		return ErrCompanyNameIsEmpty
	}

	if c.Slug == "" {
		c.Slug = strings.ToLower(c.Name)
	}

	if c.Employees == 0 {
		return ErrCompanyEmployeesZero
	}

	return nil
}
