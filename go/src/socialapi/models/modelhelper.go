package models

import "socialapi/db"

func Save(d interface{}) error {
	return db.DB.Save(d).Error
}

func Delete(d interface{}) error {
	return db.DB.Delete(d).Error
}

func First(d interface{}, id int64) error {
	return db.DB.First(d, id).Error
}
