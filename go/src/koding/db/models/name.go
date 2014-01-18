package models

// import "labix.org/v2/mgo/bson"

type Name struct {
	// Id    bson.ObjectId `bson:"_id"`
	Name  string `bson:"name"`
	Slugs []Slug `bson:"slugs"`
}

type Slug struct {
	ConstructorName string `bson:"constructorName"`
	CollectionName  string `bson:"collectionName"`
	UsedAsPath      string `bson:"usedAsPath"`
	Slug            string `bson:"slug"`
	Group           string `bson:"group,omitempty"`
}
