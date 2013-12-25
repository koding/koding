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

  log.Info("Topic Modifier worker started")
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

//Deletes given tags. Tags are removed from post bodies and collections.
//Tag relations are also removed.
func deleteTags(tagId string) {
  log.Info("Deleting obsolete tag")
  tag, err := helper.GetTagById(tagId)
  if err != nil {
    log.Error("Tag not found - Id: ", tagId)
    return
  }

  selector := helper.Selector{"targetId": helper.GetObjectId(tagId), "as": "tag"}

  rels := helper.GetRelationships(selector)
  updatePosts(rels, "")
  updateTagRelationships(rels, &Tag{})

  postRels := convertTagRelationships(rels)
  updateTagRelationships(postRels, &Tag{})

  tag.Counts = TagCount{}
  helper.UpdateTag(tag)
}

func mergeTags(tagId string) {
  log.Info("Merging topics")

  tag, err := helper.GetTagById(tagId)
  if err != nil {
    log.Error("Tag not found - Id: ", tagId)
    return
  }

  synonym, err := FindSynonym(tagId)
  if err != nil {
    log.Error("Synonym not found - Id %s", tagId)
    return
  }
  log.Info("Merging Topic %s into %s", tag.Title, synonym.Title)

  selector := helper.Selector{"targetId": helper.GetObjectId(tagId), "as": "tag"}
  tagRels := helper.GetRelationships(selector)

  taggedPostCount := len(tagRels)
  log.Info("%v tagged posts found", taggedPostCount)
  if taggedPostCount > 0 {
    updatedPostRels := updatePosts(tagRels, synonym.Id.Hex())
    postCount := len(updatedPostRels)
    log.Info("Merged Post count %d", postCount)
    synonym.Counts.Post += postCount

    updateTagRelationships(updatedPostRels, synonym)
    postRels := convertTagRelationships(updatedPostRels)
    updateTagRelationships(postRels, synonym)
  }

  updateCounts(tag, synonym)
  synonym.Counts.Followers += updateFollowers(tag, synonym)
  helper.UpdateTag(synonym)
  tag.Counts = TagCount{} // reset counts
  helper.UpdateTag(tag)
}

func convertTagRelationships(tagRels []Relationship) (postRelationships []Relationship) {
  for _, tagRel := range tagRels {
    postRelationships = append(postRelationships, swapTagRelation(&tagRel, "post"))
  }

  return postRelationships
}

//Update post tags with new ones. When newTagId = "" or post already
//includes new tag, then it just removes old tag and also removes tag relationship
//Returns Filtered Relationships
func updatePosts(rels []Relationship, newTagId string) (filteredRels []Relationship) {
  for _, rel := range rels {
    tagId := rel.TargetId.Hex()
    post, err := helper.GetStatusUpdateById(rel.SourceId.Hex())
    if err != nil {
      log.Error("Status Update Not Found - Id: %s, Err: %s", rel.SourceId.Hex(), err)
      continue
    }

    tagIncluded := updatePostBody(post, tagId, newTagId)
    if strings.TrimSpace(post.Body) == "" {
      DeleteStatusUpdate(post.Id.Hex())
    } else {
      err = helper.UpdateStatusUpdate(post)
    }

    if err != nil {
      log.Error(err.Error())
      continue
    }

    if !tagIncluded {
      filteredRels = append(filteredRels, rel)
    } else {
      RemoveRelationship(&rel)
      postRel := swapTagRelation(&rel, "post")
      RemoveRelationship(&postRel)
    }
  }

  return filteredRels
}

//Replaces given post tagId with new one. If new tag is already included
//then it just removes old one.
//Returns tag included information
func updatePostBody(s *StatusUpdate, tagId string, newTagId string) (tagIncluded bool) {
  var newTag string
  tagIncluded = false
  if newTagId != "" {
    newTag = fmt.Sprintf("|#:JTag:%v|", newTagId)
    //new tag already included in post
    if strings.Index(s.Body, newTag) != -1 {
      tagIncluded = true
      newTag = ""
    }
  }

  modifiedTag := fmt.Sprintf("|#:JTag:%v|", tagId)
  s.Body = strings.Replace(s.Body, modifiedTag, newTag, -1)
  return tagIncluded
}

//Removes old tag relationships and creates new ones if synonym tag does exists
func updateTagRelationships(rels []Relationship, synonym *Tag) {
  for _, rel := range rels {
    RemoveRelationship(&rel)
    if synonym.Id.Hex() != "" {
      if rel.TargetName == "JTag" {
        rel.TargetId = synonym.Id
      } else {
        rel.SourceId = synonym.Id
      }
      rel.Id = helper.NewObjectId()
      CreateRelationship(&rel)
    }
  }
}

func updateCounts(tag *Tag, synonym *Tag) {
  synonym.Counts.Following += tag.Counts.Following // does this have any meaning?
  synonym.Counts.Tagged += tag.Counts.Tagged
}

//Moves follower information under the new topic. If user is already following
//new topic, then she is not added as follower.
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

func swapTagRelation(r *Relationship, as string) Relationship {
  return Relationship{
    As:         as,
    SourceId:   r.TargetId,
    SourceName: r.TargetName,
    TargetId:   r.SourceId,
    TargetName: r.SourceName,
    TimeStamp:  r.TimeStamp,
  }
}
