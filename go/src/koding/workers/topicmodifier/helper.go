package topicmodifier

import (
	. "koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"labix.org/v2/mgo/bson"
)

// hard delete.
func DeleteStatusUpdate(id string) error {
	err := RemoveComments(id)
	if err != nil {
		log.Error("Empty Status Update Cannot be deleted: %v", err)
		return err
	}

	err = RemovePostRelationships(id)
	if err != nil {
		log.Error("Empty Status Update Cannot be deleted: %v", err)
		return err
	}

	err = helper.DeleteStatusUpdateById(id)
	if err != nil {
		log.Error("Empty Status Update Cannot be deleted: %v", err)
		return err
	}

	log.Info("Deleted Empty Status Update")
	return nil
}

//Creates Relationships both in mongo and neo4j
func CreateRelationship(relationship *Relationship) error {
	err := CreateGraphRelationship(relationship)
	if err != nil {
		return err
	}
	log.Debug("Add Mongo Relationship")
	return helper.AddRelationship(relationship)
}

//Removes Relationships both from mongo and neo4j
func RemoveRelationship(relationship *Relationship) error {
	err := RemoveGraphRelationship(relationship)
	if err != nil {
		return err
	}

	selector := helper.Selector{
		"sourceId": relationship.SourceId,
		"targetId": relationship.TargetId,
		"as":       relationship.As,
	}
	log.Debug("Delete Mongo Relationship")
	return helper.DeleteRelationships(selector)
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
	rels, err := helper.GetAllRelationships(selector)
	if err != nil {
		return err
	}
	if len(rels) == 0 {
		return nil
	}

	for _, rel := range rels {
		err = RemoveRelationship(&rel)
		if err != nil {
			return err
		}
		removedNodeIds = append(removedNodeIds, rel.SourceId)
	}

	//remove comment relationships with opposite orientation
	selector = helper.Selector{"targetId": helper.Selector{"$in": removedNodeIds}}
	err = RemoveRelationships(selector)
	if err != nil {
		return err
	}

	selector = helper.Selector{"_id": helper.Selector{"$in": removedNodeIds}}
	return helper.DeleteComment(selector)
}

func RemovePostRelationships(id string) error {
	objectId := helper.GetObjectId(id)
	// remove post relationships
	selector := helper.Selector{"$or": []helper.Selector{
		helper.Selector{"sourceId": objectId},
		helper.Selector{"targetId": objectId},
	}}
	return RemoveRelationships(selector)
}

func RemoveRelationships(selector helper.Selector) error {
	rels, err := helper.GetAllRelationships(selector)
	if err != nil {
		return err
	}

	for _, rel := range rels {
		if err = RemoveRelationship(&rel); err != nil {
			return err
		}
	}
	return nil
}
