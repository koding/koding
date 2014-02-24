package topicmodifier

import (
	"fmt"
	. "koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"strings"
)

const LIMIT = 50

var Completed = false

// deleteTags removes given tags from post body and deletes related tag relationships.
func deleteTags(tagId string) error {
	log.Info("Deleting topic")

	tag, err := helper.GetTagById(tagId)
	if err != nil {
		if err == helper.ErrNotFound {
			return fmt.Errorf("Tag not found - Id: %s", tagId)
		}
		return err
	}
	log.Info("Deleting %s", tag.Title)

	return updateTags(tag, &Tag{})
}

// mergeTags merges given tag with its synonym.
func mergeTags(tagId string) error {
	log.Info("Merging topics")

	tag, err := helper.GetTagById(tagId)
	if err != nil {
		if err == helper.ErrNotFound {
			return fmt.Errorf("Tag not found - Id: %s", tagId)
		}
		return err
	}

	synonym, err := FindSynonym(tagId)
	if err != nil {
		if err == helper.ErrNotFound {
			return fmt.Errorf("Synonym not found - Id %s", tagId)
		}
		return err
	}

	log.Info("Merging Topic %s into %s", tag.Title, synonym.Title)

	return updateTags(tag, synonym)
}

func updateTags(tag *Tag, synonym *Tag) error {
	selector := helper.Selector{"targetId": helper.GetObjectId(tag.Id.Hex()), "as": "tag"}
	rels, err := helper.GetSomeRelationships(selector, LIMIT)
	if err != nil {
		return err
	}

	postCount := len(rels)
	log.Info("%d tagged posts found", postCount)
	if postCount == 0 {
		return updateFollowers(tag, synonym)
	}

	updatedPostRels := updatePosts(rels, synonym.Id.Hex())

	updatedPostCount := len(updatedPostRels)
	log.Info("Updated Post count %d", updatedPostCount)

	err = updateTagRelationships(updatedPostRels, synonym)
	if err != nil && err != helper.ErrNotFound {
		return err
	}
	postRels := convertTagRelationships(updatedPostRels)
	err = updateTagRelationships(postRels, synonym)
	if err != nil && err != helper.ErrNotFound {
		return err
	}

	tag.Counts.Post -= postCount
	if err = helper.UpdateTag(tag); err != nil {
		return err
	}

	if synonym.Id.Hex() != "" {
		synonym.Counts.Post += updatedPostCount
		if err = helper.UpdateTag(synonym); err != nil {
			return err
		}
	}

	if postCount < LIMIT {
		return updateFollowers(tag, synonym)
	}

	return nil
}

func convertTagRelationships(tagRels []Relationship) (postRelationships []Relationship) {
	for _, tagRel := range tagRels {
		postRelationships = append(postRelationships, swapTagRelation(&tagRel, "post"))
	}

	return postRelationships
}

//updatePosts updates post body and post relationships according to given tag
//information. When newTagId = "" or when new tag is already included in post,
//then it just removes old tag (|JTag:x|) from post body and also removes post
//relationships.
//Returns Post Relationships where the old tag information is replaced.
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
			err = DeleteStatusUpdate(post.Id.Hex()) // delete empty post
		} else {
			err = helper.UpdateStatusUpdate(post) // update post body
		}

		if err != nil {
			log.Error("%v", err)
			continue
		}

		if !tagIncluded {
			filteredRels = append(filteredRels, rel)
		} else {
			RemoveRelationship(&rel) // remove JStatusUpdate - tag - JTag relationship
			postRel := swapTagRelation(&rel, "post")
			RemoveRelationship(&postRel) // remove JTag - post - JStatusUpdate relationship
		}
	}

	return filteredRels
}

//updatePostBody updates post body with given tags. It replaces already existing
//tag |#:JTag:[tagId]| with new one as |#:JTag:[newTagId]|. If new tag is already
//included in the post then it is not appended.
//E.g. post is #go #golang. when we merge #go to #golang, post becomes as #golang #golang.
//for preventing this doubling effect we drop one tag. Finally post becomes: #golang
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

//updateTagRelationships replaces old tag relationships with new ones.
//When synonym Tag is an empty object it just removes old relationships.
func updateTagRelationships(rels []Relationship, synonym *Tag) error {
	for _, rel := range rels {
		err := RemoveRelationship(&rel)
		if err != nil {
			return err
		}
		if synonym.Id.Hex() == "" {
			continue
		}
		//tag is replaced by synonym
		if rel.TargetName == "JTag" {
			rel.TargetId = synonym.Id
		} else {
			rel.SourceId = synonym.Id
		}
		rel.Id = helper.NewObjectId()
		if err = CreateRelationship(&rel); err != nil {
			return err
		}
	}
	return nil
}

// updateCounts updates tag count information. But here not sure if the
// following and tagged counts really have a meaning.
func updateCounts(tag *Tag, synonym *Tag) {
	synonym.Counts.Following += tag.Counts.Following
	tag.Counts.Following = 0
	synonym.Counts.Tagged += tag.Counts.Tagged
	tag.Counts.Tagged = 0
}

// updateFollowers appends old tag followers to new one. When user is already
// following new topic, then she is not appended as follower. It also updates
// tag follower counts.
func updateFollowers(tag *Tag, synonym *Tag) error {
	selector := helper.Selector{
		"sourceId":   tag.Id,
		"as":         "follower",
		"targetName": "JAccount",
	}

	rels, err := helper.GetSomeRelationships(selector, LIMIT)
	if err != nil {
		return err
	}
	followerCount := len(rels)
	log.Info("%v followers found", followerCount)
	if followerCount == 0 {
		updateCounts(tag, synonym)
		helper.UpdateTag(tag)
		helper.UpdateTag(synonym)
		Completed = true
		return nil
	}

	if synonym.Id.Hex() != "" {
		err = mergeFollowers(rels, synonym)
		if err != nil {
			return err
		}
	} else {
		updateTagRelationships(rels, &Tag{})
	}

	tag.Counts.Followers -= followerCount
	if followerCount < LIMIT {
		updateCounts(tag, synonym)
		Completed = true
	}
	helper.UpdateTag(tag)
	helper.UpdateTag(synonym)
	return nil
}

// mergeFollowers merges topic followers.
func mergeFollowers(rels []Relationship, synonym *Tag) error {
	var existingFollowers []Relationship
	var newFollowers []Relationship

	for _, rel := range rels {
		selector := helper.Selector{
			"sourceId": synonym.Id,
			"targetId": rel.TargetId,
			"as":       rel.As,
		}

		// checking if relationship already exists for the synonym
		_, err := helper.GetRelationship(selector)
		//because there are two relations as account -> follower -> tag and
		//tag -> follower -> account, we have added
		if err != nil {
			if err == helper.ErrNotFound {
				newFollowers = append(newFollowers, rel)
			} else {
				return err
			}
		} else {
			existingFollowers = append(existingFollowers, rel)
		}
	}

	log.Info("%v users are already following new topic", len(existingFollowers))
	if len(existingFollowers) > 0 {
		err := updateTagRelationships(existingFollowers, &Tag{})
		if err != nil {
			return err
		}
	}

	newFollowerCount := len(newFollowers)
	if newFollowerCount > 0 {
		log.Info("%v users followed new topic", len(newFollowers))
		err := updateTagRelationships(newFollowers, synonym)
		if err != nil {
			return err
		}
		synonym.Counts.Followers += newFollowerCount
	}

	return nil
}

// swapTagRelation swaps source and target data of relationships. It is used
// for converting bidirectional relationships.
func swapTagRelation(r *Relationship, as string) Relationship {
	return Relationship{
		As:         as,
		SourceId:   r.TargetId,
		SourceName: r.TargetName,
		TargetId:   r.SourceId,
		TargetName: r.SourceName,
		TimeStamp:  r.TimeStamp,
		Data:       r.Data,
	}
}
