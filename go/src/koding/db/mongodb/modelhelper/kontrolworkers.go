package modelhelper

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"log"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	WorkersCollection = "jKontrolWorkers"
	WorkersDB         = "kontrol"
)

var kontrolDB *mongodb.MongoDB

func KontrolWorkersInit(url string) {
	kontrolDB = mongodb.NewMongoDB(url)
}

func GetWorker(uuid string) (models.Worker, error) {
	result := models.Worker{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"uuid": uuid}).One(&result)
	}

	err := kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, query)
	if err != nil {
		return result, fmt.Errorf("no worker with the uuid %s exist.", uuid)
	}

	return result, nil
}

func UpdateIDWorker(worker models.Worker) {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(worker.ObjectId, worker)
	}

	err := kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, query)
	if err != nil {
		log.Println(err)
	}
}

func UpdateWorker(worker models.Worker) {
	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"uuid": worker.Uuid}, worker)
	}

	err := kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, query)
	if err != nil {
		log.Println(err)
	}
}

func UpsertWorker(worker models.Worker) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"uuid": worker.Uuid}, worker)
		return err
	}

	return kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, query)
}

func DeleteWorker(uuid string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"uuid": uuid})
	}

	return kontrolDB.RunOnDatabase(WorkersDB, WorkersCollection, query)
}
