package modelhelper

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
)

func GetWorker(uuid string) (models.Worker, error) {
	result := models.Worker{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uuid": uuid}).One(&result)
	}

	err := mongodb.Run("jKontrolWorkers", query)
	if err != nil {
		return result, fmt.Errorf("no worker with the uuid %s exist.", uuid)
	}

	return result, nil
}

func UpdateIDWorker(worker models.Worker) {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(worker.ObjectId, worker)
	}

	err := mongodb.Run("jKontrolWorkers", query)
	if err != nil {
		log.Println(err)
	}
}

func UpdateWorker(worker models.Worker) {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"uuid": worker.Uuid}, worker)
	}

	err := mongodb.Run("jKontrolWorkers", query)
	if err != nil {
		log.Println(err)
	}
}

func UpsertWorker(worker models.Worker) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"uuid": worker.Uuid}, worker)
		return err
	}

	return mongodb.Run("jKontrolWorkers", query)
}

func DeleteWorker(uuid string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"uuid": uuid})
	}

	return mongodb.Run("jKontrolWorkers", query)
}
