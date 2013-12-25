package main

import (
  . "koding/db/models"
  helper "koding/db/mongodb/modelhelper"
  "labix.org/v2/mgo/bson"
)

// hard delete.
func DeleteStatusUpdate(id string) {

  RemoveComments(id)
  RemovePostRelationships(id)
  err := helper.DeleteStatusUpdateById(id)
  if err != nil {
    log.Error("Empty Status Update Cannot be deleted")
    return
  }

  log.Info("Deleted Empty Status Update")
}

//Creates Relationships both in mongo and neo4j
func CreateRelationship(relationship *Relationship) {
  CreateGraphRelationship(relationship)
  log.Debug("Add Mongo Relationship")
  helper.AddRelationship(relationship)
}

//Removes Relationships both from mongo and neo4j
func RemoveRelationship(relationship *Relationship) {
  RemoveGraphRelationship(relationship)
  selector := helper.Selector{
    "sourceId": relationship.SourceId,
    "targetId": relationship.TargetId,
    "as":       relationship.As,
  }
  log.Debug("Delete Mongo Relationship")
  helper.DeleteRelationship(selector)
}

//Finds synonym of a given tag by tagId
func FindSynonym(tagId string) (*Tag, error) {
  selector := helper.Selector{"sourceId": helper.GetObjectId(tagId), "as": "synonymOf"}
  synonymRel, err := helper.GetRelationship(selector)
  if err != nil {
    return nil, err
  }

  return helper.GetTagById(synonymRel.TargetId.Hex())
}

func RemoveComments(id string) error {
  objectId := helper.GetObjectId(id)
  selector := helper.Selector{"targetId": objectId, "sourceName": "JComment"}

  removedNodeIds := make([]bson.ObjectId, 0)
  rels := helper.GetRelationships(selector)
  for _, rel := range rels {
    RemoveRelationship(&rel)
    removedNodeIds = append(removedNodeIds, rel.SourceId)
  }

  //remove comment relationships with opposite orientation
  selector = helper.Selector{"targetId": helper.Selector{"$in": removedNodeIds}}
  RemoveRelationships(selector)

  selector = helper.Selector{"_id": helper.Selector{"$in": removedNodeIds}}
  return helper.DeleteComment(selector)
}

func RemovePostRelationships(id string) {
  objectId := helper.GetObjectId(id)
  // remove post relationships
  selector := helper.Selector{"$or": []helper.Selector{
    helper.Selector{"sourceId": objectId},
    helper.Selector{"targetId": objectId},
  }}
  RemoveRelationships(selector)

}

func RemoveRelationships(selector helper.Selector) {
  rels := helper.GetRelationships(selector)
  for _, rel := range rels {
    RemoveRelationship(&rel)
  }
}
