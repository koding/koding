package main

import (
  "encoding/json"
  "fmt"
  "github.com/streadway/amqp"
  . "koding/db/models"
  "koding/tools/amqputil"
  "log"
  "strings"
)

type Status string

const (
  UPDATE Status = "update"
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
  OldTagId string `json:"oldTagId"`
  TagId    string `json:"tagId"`
  Status   Status `json:"status"`
}

func init() {
  declareExchange()
}

func main() {
  log.Printf("Tag Modifier Worker Started")
  consumeMessages()
  // fetch/update related posts
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

func fetchRelatedPosts() {

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
      // get rid of this case structure.
      switch modifierData.Status {
      default:
        log.Println("Unknown modification status")
        // rawMsg.Ack(false)
      case UPDATE:
        updateTags(modifierData)
      case DELETE:
        deleteTags(modifierData)
      case MERGE:
        mergeTags(modifierData)
      }
    }

    modifyMessage()

  }
}

func isTagValid(tagId string, fn func(string) Tag) bool {
  tag := fn(tagId)
  if (tag != Tag{}) {
    return true
  }
  return false
}

func updateTags(modifierData *TagModifierData) {
  log.Println("update")
  // fetch tag
  // fetch related posts
}

func deleteTags(modifierData *TagModifierData) {
  log.Println("delete")
  if isTagValid(modifierData.TagId, FindDeletedTagById) {
    log.Println("Valid tag")
    rels := FindRelationshipsWithTagId(modifierData.TagId)
    deleteTagsFromPosts(rels)
  }
  //ack

}

func deleteTagsFromPosts(rels []Relationship) {
  for _, rel := range rels {
    tagId := rel.TargetId.Hex()
    post := FindPostWithId(rel.SourceId.Hex())
    updatePost(&post, tagId)
    RemoveTagRelationship(rel)
  }
  log.Printf("Deleted %d tags", len(rels))
}

//it could take fn parameter for deleting/appending tag
func updatePost(post *StatusUpdate, tagId string) {
  modifiedTag := fmt.Sprintf("|#:JTag:%v|", tagId)
  post.Body = strings.Replace(post.Body, modifiedTag, "", -1)
  // log.Println("PostBody:", post.Body)
  UpdatePost(post)
}

func mergeTags(modifierData *TagModifierData) {
  log.Println("merge")
}
