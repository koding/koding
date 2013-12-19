package main

import (
  . "koding/db/models"
  "koding/tools/config"
  "labix.org/v2/mgo"
  "labix.org/v2/mgo/bson"
  "log"
)

var (
  DATABASE          *mgo.Database
  MONGO_CONN_STRING = config.Current.Mongo
  REL_COLL          *mgo.Collection
  TAG_COLL          *mgo.Collection
  POST_COLL         *mgo.Collection
)

type Trash struct {
  Tag Tag `bson:"data"`
}

func init() {
  initMongo()
}

func initMongo() {
  session, err := mgo.Dial(MONGO_CONN_STRING)
  if err != nil {
    panic(err)
  }
  DATABASE = session.DB("koding")
  REL_COLL = DATABASE.C("relationships")
  TAG_COLL = DATABASE.C("jTags")
  POST_COLL = DATABASE.C("jNewStatusUpdates") //CtF this will change
}

func FindTagById(tagId string) Tag {
  tag := Tag{}
  query := bson.M{
    "_id": bson.ObjectIdHex(tagId),
  }

  if err := TAG_COLL.Find(query).One(&tag); err != nil {
    log.Println("Error in Tag Fetching: ", err)
    panic(err)
  }

  return tag
}

func FindRelationships(query bson.M) []Relationship {
  var relationships []Relationship
  if err := REL_COLL.Find(query).All(&relationships); err != nil {
    log.Println("Relationship fetch error", err)
    panic(err)
  }
  return relationships
}

func FindRelationship(query bson.M) (Relationship, error) {
  relationship := Relationship{}
  if err := REL_COLL.Find(query).One(&relationship); err != nil {
    return relationship, err
  }
  return relationship, nil
}

func FindPostWithId(id string) StatusUpdate {
  post := StatusUpdate{}
  query := bson.M{
    "_id": bson.ObjectIdHex(id),
  }

  if err := POST_COLL.Find(query).One(&post); err != nil {
    log.Println("Post fetch error", err)
    panic(err)
  }

  return post
}

func UpdatePost(post *StatusUpdate) {
  // defensive post id check must be added
  if err := POST_COLL.UpdateId(post.Id, post); err != nil {
    log.Println("Post update error", err)
    panic(err)
  }
}

func UpdateTag(tag *Tag) {
  if err := TAG_COLL.UpdateId(tag.Id, tag); err != nil {
    log.Println("Tag update error", err)
    panic(err)
  }
}

func FindSynonym(tagId string) Tag {
  rels := FindRelationships(bson.M{"sourceId": bson.ObjectIdHex(tagId), "as": "synonymOf"})
  if len(rels) > 0 {
    synonym := rels[0]
    return FindTagById(synonym.TargetId.Hex())
  } else {
    return Tag{}
  }
}

func RemoveRelationship(rel Relationship) error {
  return REL_COLL.Remove(bson.M{"_id": rel.Id})
}

func CreateRelationship(rel Relationship) error {
  if err := REL_COLL.Insert(rel); err != nil {
    log.Println("Insert Relationship error", err)
    return err
  }
  return nil
}
