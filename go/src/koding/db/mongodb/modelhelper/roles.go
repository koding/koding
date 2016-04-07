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

// FetchAccountGroups lists the group memberships of a given username
func FetchAccountGroups(username string) ([]string, error) {
	account, err := GetAccount(username)
	if err != nil {
		return nil, err
	}

	selector := Selector{
		"sourceName": "JGroup",
		"targetId":   account.Id,
		"targetName": "JAccount",
		"as":         bson.M{"$in": []string{"owner", "admin", "member"}},
	}

	rels, err := GetAllRelationships(selector)
	if err != nil {
		return nil, err
	}

	if len(rels) == 0 {
		return nil, nil
	}

	var ids []string
	for _, rel := range rels {
		ids = append(ids, rel.SourceId.Hex())
	}

	groups, err := GetGroupFieldsByIds(ids, []string{"slug"})
	if err != nil {
		return nil, err
	}

	// unify the list
	slugs := make(map[string]struct{})
	for _, group := range groups {
		slugs[group.Slug] = struct{}{}
	}

	var slugList []string
	for slug := range slugs {
		slugList = append(slugList, slug)
	}

	return slugList, nil
}
