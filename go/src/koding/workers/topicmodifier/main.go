package main

import (
  "encoding/json"
  "fmt"
  "github.com/streadway/amqp"
  . "koding/db/models"
  "koding/tools/amqputil"
  "labix.org/v2/mgo/bson"
  "log"
  "strings"
)

type Status string

const (
  DELETE Status = "delete"
  MERGE  Status = "merge"
)

var (
  EXCHANGE_NAME     = "topicModifierExchange"
  WORKER_QUEUE_NAME = "topicModifierWorkerQueue"
)

type Consumer struct {
  conn    *amqp.Connection
  channel *amqp.Channel
  name    string
}

type TagModifierData struct {
  TagId  string `json:"tagId"`
  Status Status `json:"status"`
}

func init() {
  declareExchange()
}

func main() {
  log.Printf("Tag Modifier Worker Started")
  consumeMessages()
  // ack message
}

func declareExchange() {

  connection := amqputil.CreateConnection("exchangeDeclareConnection")

  channel := amqputil.CreateChannel(connection)

  err := channel.ExchangeDeclare(EXCHANGE_NAME, "fanout", true, false, false, false, nil)
  if err != nil {
    log.Println("exchange.declare: %s", err)
    panic(err)
  }

  //name, durable, autoDelete, exclusive, noWait, args Table
  _, err = channel.QueueDeclare(WORKER_QUEUE_NAME, true, false, false, false, nil)
  if err != nil {
    log.Println("queue.declare: %s", err)
    panic(err)
  }
  err = channel.QueueBind(WORKER_QUEUE_NAME, "", EXCHANGE_NAME, false, nil)
  if err != nil {
    log.Println("queue.bind: %s", err)
    panic(err)
  }

}

func consumeMessages() {
  c := &Consumer{
    conn:    nil,
    channel: nil,
    name:    "",
  }

  c.name = "tagModifier"
  c.conn = amqputil.CreateConnection(c.name)
  c.channel = amqputil.CreateChannel(c.conn)

  postData, err := c.channel.Consume(WORKER_QUEUE_NAME, c.name, false, false, false, false, nil)
  if err != nil {
    log.Printf("Consume error %s", err)
    panic(err)
  }

  for rawMsg := range postData {
    modifierData := &TagModifierData{}
    if err = json.Unmarshal([]byte(rawMsg.Body), modifierData); err != nil {
      log.Println("Wrong Post Format", err, rawMsg)
    }

    modifyMessage := func() {
      tagId := modifierData.TagId
      switch modifierData.Status {
      default:
        log.Println("Unknown modification status")
      case DELETE:
        deleteTags(tagId)
      case MERGE:
        mergeTags(tagId)
      }
      rawMsg.Ack(false)
    }

    modifyMessage()

  }
}

func deleteTags(tagId string) {
  log.Println("delete")
  if tag := FindTagById(tagId); (tag != Tag{}) {
    log.Println("Valid tag")
    rels := FindRelationships(bson.M{"targetId": bson.ObjectIdHex(tagId), "as": "tag"})
    updatePosts(rels, "")
    updateRelationships(rels, &Tag{})
  }
  //ack

}

func mergeTags(tagId string) {
  log.Println("merge")

  if tag := FindTagById(tagId); (tag != Tag{}) {
    log.Println("Valid tag")

    synonym := FindSynonym(tagId)
    tagRels := FindRelationships(bson.M{"targetId": bson.ObjectIdHex(tagId), "as": "tag"})
    if len(tagRels) > 0 {
      updatePosts(tagRels, synonym.Id.Hex())
      updateRelationships(tagRels, &synonym)
    }

    postRels := FindRelationships(bson.M{"sourceId": bson.ObjectIdHex(tagId), "as": "post"})
    if len(postRels) > 0 {
      updateRelationships(postRels, &synonym)
      updateCounts(&tag, &synonym)
    }
    UpdateTag(&synonym)
    tag.Counts = TagCount{} // reset counts
    UpdateTag(&tag)
    updateFollowers(&tag, &synonym)
  }
}

func updatePosts(rels []Relationship, newTagId string) {
  var newTag string
  if newTagId != "" {
    newTag = fmt.Sprintf("|#:JTag:%v|", newTagId)
  }

  for _, rel := range rels {
    tagId := rel.TargetId.Hex()
    post := FindPostWithId(rel.SourceId.Hex())
    modifiedTag := fmt.Sprintf("|#:JTag:%v|", tagId)
    post.Body = strings.Replace(post.Body, modifiedTag, newTag, -1)
    UpdatePost(&post)
  }
  log.Printf("%v Posts updated", len(rels))
}

func updateRelationships(rels []Relationship, synonym *Tag) {
  for _, rel := range rels {
    removeRelationship(rel)
    if (synonym != &Tag{}) {
      if rel.TargetName == "JTag" {
        rel.TargetId = synonym.Id
      } else {
        rel.SourceId = synonym.Id
      }
      rel.Id = bson.NewObjectId()
      createRelationship(rel)
    }
  }
}

func updateCounts(tag *Tag, synonym *Tag) {
  synonym.Counts.Following += tag.Counts.Following
  synonym.Counts.Followers += tag.Counts.Followers
  synonym.Counts.Post += tag.Counts.Post
  synonym.Counts.Tagged += tag.Counts.Tagged
}

func updateFollowers(tag *Tag, synonym *Tag) {
  var arr [2]bson.M
  arr[0] = bson.M{
    "targetId": tag.Id,
    "as":       "follower",
  }
  arr[1] = bson.M{
    "sourceId": tag.Id,
    "as":       "follower",
  }
  rels := FindRelationships(bson.M{"$or": arr})
  log.Printf("%v follower rels found", len(rels))
  if len(rels) > 0 {
    updateRelationships(rels, synonym)
  }
}

func createRelationship(relationship Relationship) {
  CreateGraphRelationship(relationship)
  CreateRelationship(relationship)
}

func removeRelationship(relationship Relationship) {
  RemoveGraphRelationship(relationship)
  RemoveRelationship(relationship)

}
