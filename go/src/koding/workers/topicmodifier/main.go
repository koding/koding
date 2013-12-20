package main

import (
  "encoding/json"
  "fmt"
  logging "github.com/op/go-logging"
  "github.com/streadway/amqp"
  . "koding/db/models"
  helper "koding/db/mongodb/modelhelper"
  "koding/messaging/rabbitmq"
  "labix.org/v2/mgo"
  stdlog "log"
  "os"
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
  log               = logging.MustGetLogger("TopicModifier")
)

type TagModifierData struct {
  TagId  string `json:"tagId"`
  Status Status `json:"status"`
}

func init() {
  configureLogger()
}

func main() {
  exchange := rabbitmq.Exchange{
    Name:    EXCHANGE_NAME,
    Type:    "fanout",
    Durable: true,
  }

  queue := rabbitmq.Queue{
    Name:    WORKER_QUEUE_NAME,
    Durable: true,
  }

  binding := rabbitmq.BindingOptions{
    RoutingKey: "",
  }

  consumerOptions := rabbitmq.ConsumerOptions{
    Tag: "TopicModifier",
  }

  consumer, err := rabbitmq.NewConsumer(exchange, queue, binding, consumerOptions)
  if err != nil {
    log.Error("%v", err)
    return
  }

  defer consumer.Shutdown()
  err = consumer.QOS(3)
  if err != nil {
    panic(err)
  }

  defer PUBLISHER.Shutdown()

  log.Info("Tag Modifier worker started")
  consumer.RegisterSignalHandler()
  consumer.Consume(messageConsumer)
}

func configureLogger() {
  logging.SetLevel(logging.INFO, "TopicModifier")
  log.Module = "TopicModifier"
  logging.SetFormatter(logging.MustStringFormatter("%{level:-3s} ▶ %{message}"))
  stderrBackend := logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
  stderrBackend.Color = true
  logging.SetBackend(stderrBackend)
}

var messageConsumer = func(delivery amqp.Delivery) {

  modifierData := &TagModifierData{}
  if err := json.Unmarshal([]byte(delivery.Body), modifierData); err != nil {
    log.Error("Wrong Post Format", err, delivery)
  }

  tagId := modifierData.TagId
  switch modifierData.Status {
  default:
    log.Error("Unknown modification status %s", modifierData.Status)
  case DELETE:
    deleteTags(tagId)
  case MERGE:
    mergeTags(tagId)
  }
  delivery.Ack(false)

}

func deleteTags(tagId string) {
  log.Println("delete")
  if tag := FindTagById(tagId); (tag != Tag{}) {
    log.Println("Valid tag")
    rels := FindRelationships(bson.M{"targetId": bson.ObjectIdHex(tagId), "as": "tag"})
    updatePosts(rels, "")
    updateRelationships(rels, &Tag{})
  }
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
    synonym.Counts.Followers += updateFollowers(&tag, &synonym)
    UpdateTag(&synonym)
    tag.Counts = TagCount{} // reset counts
    UpdateTag(&tag)
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
  synonym.Counts.Following += tag.Counts.Following // does this have any meaning?
  // synonym.Counts.Followers += tag.Counts.Followers
  synonym.Counts.Post += tag.Counts.Post
  synonym.Counts.Tagged += tag.Counts.Tagged
}

func updateFollowers(tag *Tag, synonym *Tag) int {
  selector := helper.Selector{
    "sourceId":   tag.Id,
    "as":         "follower",
    "targetName": "JAccount",
  }

  rels := helper.GetRelationships(selector)
  var oldFollowers []Relationship
  var newFollowers []Relationship

  for _, rel := range rels {
    selector["sourceId"] = synonym.Id
    selector["targetId"] = rel.TargetId

    // checking if relationship already exists for the synonym
    _, err := helper.GetRelationship(selector)
    //because there are two relations as account -> follower -> tag and
    //tag -> follower -> account, we have added
    if err != nil {
      if err == mgo.ErrNotFound {
        newFollowers = append(newFollowers, rel)
      } else {
        log.Error(err.Error())
        return 0
      }
    } else {
      oldFollowers = append(oldFollowers, rel)
    }
  }

  log.Info("%v users are already following new topic", len(oldFollowers))
  if len(oldFollowers) > 0 {
    updateTagRelationships(oldFollowers, &Tag{})
  }
  log.Info("%v users followed new topic", len(newFollowers))
  if len(newFollowers) > 0 {
    updateTagRelationships(newFollowers, synonym)
  }

  return len(newFollowers)
}

func createRelationship(relationship Relationship) {
  CreateGraphRelationship(relationship)
  CreateRelationship(relationship)
}

func removeRelationship(relationship Relationship) {
  RemoveGraphRelationship(relationship)
  RemoveRelationship(relationship)
//Finds synonym of a given tag by tagId
func FindSynonym(tagId string) (*Tag, error) {
  selector := helper.Selector{"sourceId": helper.GetObjectId(tagId), "as": "synonymOf"}
  synonymRel, err := helper.GetRelationship(selector)
  if err != nil {
    return nil, err
  }

  return helper.GetTagById(synonymRel.TargetId.Hex())
}
