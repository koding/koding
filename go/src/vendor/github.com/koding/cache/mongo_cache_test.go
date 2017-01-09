package cache

import (
	"os"
	"testing"
	"time"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	// session is the default session with default options
	session = initMongo()
)

func TestMongoCacheSetOptionFuncs(t *testing.T) {
	mgoCache := NewMongoCacheWithTTL(session)
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}

	duration := time.Minute * 3
	cacheTTL := NewMongoCacheWithTTL(session, SetTTL(duration))
	defer mgoCache.StopGC()
	if cacheTTL == nil {
		t.Fatal("ttl config should not be nil")
	}
	if cacheTTL.TTL != duration {
		t.Fatalf("config ttl time should equal to %v", duration)
	}

	// check multiple options
	collName := "testingCollectionName"
	cache := NewMongoCacheWithTTL(session, SetCollectionName(collName), SetGCInterval(duration), StartGC())
	defer mgoCache.StopGC()
	if cache == nil {
		t.Fatal("cache should not be nil")
	}
	if cache.CollectionName != collName {
		t.Fatalf("cache collection name should equal %s", collName)
	}
	if cache.GCStart != true {
		t.Fatal("cache StartGC option should not be true")
	}

	if cache.GCInterval != duration {
		t.Fatalf("cache GCInterval option should equal %v", duration)
	}
}

func TestMongoCacheGet(t *testing.T) {
	mgoCache := NewMongoCacheWithTTL(session)
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}
	if _, err := mgoCache.Get("test"); err != ErrNotFound {
		t.Fatalf("error is: %q", err)
	}
}

func TestMongoCacheSet(t *testing.T) {
	mgoCache := NewMongoCacheWithTTL(session)
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}
	key := bson.NewObjectId().Hex()
	value := bson.NewObjectId().Hex()

	if err := mgoCache.Set(key, value); err != nil {
		t.Fatalf("error should be nil: %q", err)
	}

	data, err := mgoCache.Get(key)
	if err != nil {
		t.Fatal("error should be nil:", err)
	}
	if data == nil {
		t.Fatal("data should not be nil")
	}
	if data != value {
		t.Fatalf("data should equal: %v ,but got: %v", value, data)
	}
}

func TestMongoCacheSetEx(t *testing.T) {
	mgoCache := NewMongoCacheWithTTL(session)
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}
	// defaultExpireDuration is 1 Minute as default
	if mgoCache.TTL != defaultExpireDuration {
		t.Fatalf("mongoCache TTL should equal %v", defaultExpireDuration)
	}

	key := bson.NewObjectId().Hex()
	value := bson.NewObjectId().Hex()

	duration := time.Second * 10
	err := mgoCache.SetEx(key, duration, value)
	if err != nil {
		t.Fatalf("error should be nil: %q", err)
	}

	document, err := mgoCache.get(key)
	if err != nil {
		t.Fatal(err)
	}
	if !time.Now().Add(duration).After(document.ExpireAt) {
		t.Fatalf("expireAt should be greater than now + %v", duration)
	}

}

func TestMongoCacheDelete(t *testing.T) {
	mgoCache := NewMongoCacheWithTTL(session)
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}
	key := bson.NewObjectId().Hex()
	value := bson.NewObjectId().Hex()

	err := mgoCache.Set(key, value)
	if err != nil {
		t.Fatalf("error should be nil: %q", err)
	}
	data, err := mgoCache.Get(key)
	if err != nil {
		t.Fatalf("error should be nil: %q", err)
	}
	if data != value {
		t.Fatalf("data should equal to %v, but got: %v", value, data)
	}

	if err = mgoCache.Delete(key); err != nil {
		t.Fatalf("err should be nil, but got %q", err)
	}

	if _, err := mgoCache.Get(key); err != ErrNotFound {
		t.Fatalf("error should equal to %q but got: %q", ErrNotFound, err)
	}
}

func TestMongoCacheTTL(t *testing.T) {
	// duration specifies the time duration to hold the data in mongo
	// after the duration interval, data will be deleted from mongoDB
	duration := time.Millisecond * 100

	mgoCache := NewMongoCacheWithTTL(session, SetTTL(duration))
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}
	defer mgoCache.StopGC()

	key, value := bson.NewObjectId().Hex(), bson.NewObjectId().Hex()

	if err := mgoCache.Set(key, value); err != nil {
		t.Fatalf("error should be nil: %q", err)
	}

	if data, err := mgoCache.Get(key); err != nil {
		t.Fatalf("error should be nil: %q", err)
	} else if data != value {
		t.Fatalf("data should equal: %v, but got: %v", value, data)
	}

	time.Sleep(duration)

	if _, err := mgoCache.Get(key); err != ErrNotFound {
		t.Fatalf("error should equal to %q but got: %q", ErrNotFound, err)
	}
}

// TestMongoCacheGC tests the garbage collector logic
// Mainly tests the GCInterval & StartGC options
func TestMongoCacheGC(t *testing.T) {
	// duration specifies the time duration to hold the data in mongo
	// after the duration interval, data will be deleted from mongoDB
	duration := time.Millisecond * 100

	mgoCache := NewMongoCacheWithTTL(session, SetTTL(duration/2), SetGCInterval(duration), StartGC())
	defer mgoCache.StopGC()
	if mgoCache == nil {
		t.Fatal("config should not be nil")
	}

	defer mgoCache.StopGC()

	key, value := bson.NewObjectId().Hex(), bson.NewObjectId().Hex()
	key1, value1 := bson.NewObjectId().Hex(), bson.NewObjectId().Hex()

	if err := mgoCache.Set(key, value); err != nil {
		t.Fatalf("error should be nil: %q", err)
	}
	if err := mgoCache.Set(key1, value1); err != nil {
		t.Fatalf("error should be nil: %q", err)
	}

	if data, err := mgoCache.Get(key); err != nil {
		t.Fatalf("error should be nil: %q", err)
	} else if data != value {
		t.Fatalf("data should equal: %v, but got: %v", value, data)
	}

	if data1, err := mgoCache.Get(key1); err != nil {
		t.Fatalf("error should be nil: %q", err)
	} else if data1 != value1 {
		t.Fatalf("data should equal: %v, but got: %v", value1, data1)
	}

	time.Sleep(duration)

	docs, err := getAllDocuments(mgoCache, key1, key1)
	if err != nil {
		t.Fatal(err)
	}

	if len(docs) != 0 {
		t.Fatalf("len should equal to 0 but got: %d", len(docs))
	}
}

func getAllDocuments(mgoCache *MongoCache, keys ...string) ([]Document, error) {
	var docs []Document
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"_id": bson.M{
				"$in": keys,
			},
		}).All(&docs)
	}

	err := mgoCache.run(mgoCache.CollectionName, query)
	if err != nil {
		return nil, err
	}

	return docs, nil
}

func initMongo() *mgo.Session {
	mongoURI := os.Getenv("MONGODB_URL")
	if mongoURI == "" {
		mongoURI = "127.0.0.1:27017/test"
	}

	ses, err := mgo.Dial(mongoURI)
	if err != nil {
		panic(err)
	}

	ses.SetSafe(&mgo.Safe{})

	return ses
}
