package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	CompanyColl = "jCompanies"
)

func CreateCompany(c *models.Company) error {
	query := insertQuery(c)
	return Mongo.Run(CompanyColl, query)
}

func UpdateCompany(selector, update bson.M) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, bson.M{"$set": update})
	}

	return Mongo.Run(CompanyColl, query)
}

func GetCompanyById(id string) (*models.Company, error) {
	company := new(models.Company)
	err := Mongo.One(CompanyColl, id, company)
	if err != nil {
		return nil, err
	}

	return company, nil
}

func RemoveCompany(companyName string) error {
	selector := bson.M{"name": companyName}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(CompanyColl, query)
}
