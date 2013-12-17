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
  TRASH_COLL        *mgo.Collection
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
  TRASH_COLL = DATABASE.C("trashes")
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

func FindDeletedTagById(tagId string) Tag {
  trash := Trash{}

  query := bson.M{
    "constructorName": "JTag",
    "data._id":        bson.ObjectIdHex(tagId),
  }

  if err := TRASH_COLL.Find(query).One(&trash); err != nil {
    log.Println("Error in Tag Fetching: ", err)
    panic(err)
  }

  return trash.Tag
}

func FindRelationshipsWithTagId(tagId string) []Relationship {
  log.Println("TagId", tagId)
  var relationships []Relationship
  query := bson.M{
    "as":       "tag",
    "targetId": bson.ObjectIdHex(tagId),
  }

  if err := REL_COLL.Find(query).All(&relationships); err != nil {
    log.Println("Relationship fetch error", err)
    panic(err)
  }
  return relationships
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

func RemoveTagRelationship(rel Relationship) {
  if err := REL_COLL.Remove(bson.M{"_id": rel.Id}); err != nil {
    log.Println("Remove Tag Relationship error", err)
    panic(err)
  }

  // bidirectional tag relationship exists here
  query := bson.M{
    "sourceId": rel.TargetId,
    "targetId": rel.SourceId,
    "as":       "post",
  }
  if err := REL_COLL.Remove(query); err != nil {
    log.Println("Remove Tag Relationship error", err)
    panic(err)
  }
}
