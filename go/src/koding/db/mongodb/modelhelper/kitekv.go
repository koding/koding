package modelhelper

import (
    "errors"
    "koding/db/models"
    "koding/db/mongodb"
    "labix.org/v2/mgo"
    "labix.org/v2/mgo/bson"
    "time"
    "fmt"
)

const KiteKeyValueCollection = "jKiteKV"


func NewKeyValue(username, kiteId, usersKey, value string) *models.KiteKeyValue {
    // mongodb has 24k number of collection limit in a single database
    // http://stackoverflow.com/questions/9858393/limits-of-number-of-collections-in-databases
    // thats why we have a single collection and use single index
    key := fmt.Sprintf("%s_%s_%s", username, kiteId, usersKey)

    return &models.KiteKeyValue{
        Key: key,
        Value: value,
        CreatedAt: time.Now().UTC(),
        ModifiedAt: time.Now().UTC(),
    }
}

func UpsertKeyValue(kv *models.KiteKeyValue) error {
    if kv.Key == "" {
        panic(errors.New("KiteKeyValue must have Key field"))
    }

    query := func(c *mgo.Collection) error {
        _, err := c.Upsert(bson.M{"key": kv.Key}, kv)
        fmt.Println("err on upsert: ", err)
        return err
    }

    return mongodb.Run(KiteKeyValueCollection, query)
}
