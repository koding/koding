package modelhelper

import (
	"errors"
	"koding/db/models"

	"gopkg.in/mgo.v2/bson"
)

// DefaultRoles stores the logical roles in a team
var DefaultRoles = []string{"owner", "admin", "member"}

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
	return HasAnyRole(username, groupName, "admin")
}

// IsMember checks if the given username is a member in given groupName
func IsMember(username, groupName string) (bool, error) {
	return HasAnyRole(username, groupName, "member")
}

// IsParticipant checks if the given username is a participant in given
// groupName, participant roles are defined in DefaultRoles.
func IsParticipant(username, groupName string) (bool, error) {
	return HasAnyRole(username, groupName, DefaultRoles...)
}

// HasAnyRole checks if the given username has the any of the given roles in given groupName
func HasAnyRole(username, groupName string, roles ...string) (bool, error) {
	if len(roles) == 0 {
		return false, errors.New("role(s) required")
	}

	group, err := GetGroup(groupName)
	if err != nil {
		return false, err
	}

	account, err := GetAccount(username)
	if err != nil {
		return false, err
	}

	selector := Selector{
		"sourceId":   group.Id,
		"sourceName": "JGroup",
		"targetId":   account.Id,
		"targetName": "JAccount",
		"as":         bson.M{"$in": roles},
	}

	count, err := RelationshipCount(selector)
	if err != nil {
		return false, err
	}

	return count > 0, nil
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
