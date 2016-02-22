package modelhelper

import (
	"fmt"
	"koding/db/models"

	"gopkg.in/mgo.v2/bson"
)

// FetchAdminAccounts fetches the admin accounts from database
func FetchAdminAccounts(groupName string) ([]models.Account, error) {
	group, err := GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	selector := Selector{
		"sourceId":   group.Id,
		"sourceName": "JGroup",
		"as":         "admin",
	}

	rels, err := GetAllRelationships(selector)
	if err != nil {
		return nil, err
	}

	ids := make([]bson.ObjectId, len(rels))
	for i, rel := range rels {
		ids[i] = rel.TargetId
	}

	return GetAccountsByIds(ids)
}

// IsAdmin checks if the given username is an admin of the given groupName
func IsAdmin(username, groupName string) (bool, error) {
	group, err := GetGroup(groupName)
	if err != nil {
		return false, fmt.Errorf("getGroup(%s) err: %s", groupName, err)
	}

	account, err := GetAccount(username)
	if err != nil {
		return false, fmt.Errorf("getAccount(%s) err: %s", username, err)
	}

	selector := Selector{
		"sourceId":   group.Id,
		"sourceName": "JGroup",
		"targetId":   account.Id,
		"targetName": "JAccount",
		"as":         "admin",
	}

	count, err := RelationshipCount(selector)
	if err != nil {
		return false, fmt.Errorf("checkAdminRelationship err: %s", err)
	}

	return count == 1, nil
}
