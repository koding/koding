package main

import (
	"errors"
	"fmt"
	. "koding/db/models"
	helper "koding/db/mongodb/modelhelper"
)

var POST_TYPES = [5]string{
	"JBlogPost",
	"JDiscussion",
	"JCodeSnip",
	"JTutorial",
	"JStatusUpdate",
}

const LIMIT = 100

type JPost struct {
	Title        string `bson:"title,omitempty"`
	OpinionCount int    `bson:"opinionCount,omitempty"`
}

var ErrAlreadyMigrated = errors.New("already migrated")

func main() {
	initPublisher()
	defer shutdown()

	for _, postType := range POST_TYPES {
		log.Notice("Starting \"%s\" migration", postType)
		m := &Migrator{
			PostType: postType,
		}
		if err := initialize(m); err != nil {
			log.Error("An error occured during migration: %s", err.Error())
		}
		GetMigrationCompletedReport(m)
	}
}

func initialize(m *Migrator) error {
	count, err := helper.CountPosts(helper.Selector{}, helper.Options{}, m.PostType)
	if err != nil {
		return err
	}
	log.Info("Found %v posts", count)

	return migrate(m)
}

func migrate(m *Migrator) error {
	o := helper.Options{
		Sort:  "meta.createdAt", //start from the oldest
		Limit: LIMIT,
		Skip:  m.Index,
	}
	posts, err := helper.GetSomePosts(helper.Selector{}, o, m.PostType)
	if err != nil {
		return err
	}
	// no more post to migrate
	if len(posts) == 0 {
		return nil
	}

	for _, post := range posts {
		m.Id = post.Id.Hex()
		post.Id = helper.NewObjectId()
		m.NewId = post.Id.Hex()
		m.Index++
		if err := verifyOrigin(&post); err != nil {
			ReportError(m, err)
			continue
		}

		if err := insertNewStatusUpdate(&post, m); err != nil {
			ReportError(m, err)
			continue
		}

		if err := migrateTags(&post, m); err != nil {
			ReportError(m, err)
			continue
		}

		if err := migrateOrigin(&post); err != nil {
			ReportError(m, err)
			continue
		}

		commenters, err := migrateComments(&post, m)
		if err != nil {
			ReportError(m, err)
			continue
		}

		if err := migrateOpinions(&post, m, commenters); err != nil {
			ReportError(m, err)
			continue
		}

		ReportSuccess(m)
	}
	return migrate(m)
}

func insertNewStatusUpdate(p *Post, m *Migrator) error {
	if p.MigrationStatus == "Completed" {
		return ErrAlreadyMigrated
	}
	exists, err := helper.CheckGroupExistence(p.Group)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("Group \"%s\" not found", p.Group)
	}
	// some status update have negative timestamp
	if p.Meta.CreatedAt.Unix() < 0 {
		return fmt.Errorf("got nil timestamp for")
	}
	p.Meta.Likes = 0 // CtF: because we are not migrating activities it is reset

	if err := migrateCodesnip(p, m); err != nil {
		return err
	}

	su := p.ConvertToStatusUpdate()
	return helper.AddStatusUpdate(su)
}

func migrateCodesnip(p *Post, m *Migrator) error {
	if m.PostType != "JCodeSnip" {
		return nil
	}

	if len(p.Attachments) > 0 {
		body, ok := p.Attachments[0]["content"]
		if !ok {
			return fmt.Errorf("Codesnip content not found")
		}
		p.Body = fmt.Sprintf("`%s`", body)
	}
	return nil
}

func migrateTags(p *Post, m *Migrator) error {
	s := helper.Selector{
		"sourceId":   helper.GetObjectId(m.Id),
		"as":         "tag",
		"targetName": "JTag",
	}
	rels, err := helper.GetAllRelationships(s)
	if err != nil {
		return err
	}
	log.Info("%v tags found", len(rels))

	for _, r := range rels {
		tagId := r.TargetId.Hex()
		// first check tag existence
		exists, err := helper.CheckTagExistence(tagId)
		if err != nil {
			return err
		}
		if !exists {
			continue
		}

		// update tag relationships
		r.Id = helper.NewObjectId()
		r.SourceId = p.Id
		r.SourceName = "JNewStatusUpdate"
		if err := helper.AddRelationship(&r); err != nil {
			return err
		}
		sr := swapRelationship(&r, "post")
		if err := helper.AddRelationship(sr); err != nil {
			return err
		}
		//append tag to status update body
		p.Body += fmt.Sprintf(" |#:JTag:%s|", tagId)
	}
	// if post is tagged
	if len(rels) > 0 {
		su := p.ConvertToStatusUpdate()
		return helper.UpdateStatusUpdate(su)
	}

	return nil
}

func migrateComments(p *Post, m *Migrator) (map[string]bool, error) {
	accounts := make(map[string]bool)
	// get all comments
	s := helper.Selector{
		"sourceId":   helper.GetObjectId(m.Id),
		"as":         "reply",
		"targetName": "JComment",
	}
	rels, err := helper.GetAllRelationships(s)
	if err != nil {
		return accounts, err
	}
	log.Info("%v comments found", len(rels))
	// posts does not have any comments
	if len(rels) == 0 {
		return accounts, nil
	}

	count := 0

	for _, r := range rels {
		comment, err := helper.GetCommentById(r.TargetId.Hex())
		if err != nil {
			if err == helper.ErrNotFound {
				log.Info("Comment not found - Id: %s", r.TargetId.Hex())
				continue
			}
			return accounts, err
		}

		// check origin existence
		originId := comment.OriginId.Hex()
		originExists, err := helper.CheckAccountExistence(originId)
		if err != nil {
			return accounts, err
		}
		if !originExists {
			continue
		}

		// add relationship: JNewStatusUpdate -> reply -> JComment
		r.Id = helper.NewObjectId()
		r.SourceId = p.Id
		r.SourceName = "JNewStatusUpdate"
		if err := helper.AddRelationship(&r); err != nil {
			return accounts, err
		}

		// get unique commenters for each post
		if _, exist := accounts[originId]; !exist {
			accounts[originId] = true
			migrateCommentOrigin(comment, p)
		}
		count++
	}

	p.RepliesCount = count

	return accounts, nil
}

// migrateOpinions migrates opinions to comments
// JDiscussion opinion JOpinion
// JAccount creator JOpinion
func migrateOpinions(p *Post, m *Migrator, commenters map[string]bool) error {
	if m.PostType != "JDiscussion" && m.PostType != "JTutorial" {
		return nil
	}
	s := helper.Selector{
		"sourceId":   helper.GetObjectId(m.Id),
		"as":         "opinion",
		"targetName": "JOpinion",
	}
	rels, err := helper.GetAllRelationships(s)
	if err != nil {
		return err
	}
	log.Info("%v opinions found", len(rels))
	// post does not have any opinion
	if len(rels) == 0 {
		return nil
	}
	count := 0
	for _, r := range rels {
		opinion, err := helper.GetOpinionById(r.TargetId.Hex())
		if err != nil {
			if err == helper.ErrNotFound {
				log.Info("Opinion not found - Id: %s", r.TargetId.Hex())
				continue
			}
			return err
		}
		// check origin existence
		originId := opinion.OriginId.Hex()
		originExists, err := helper.CheckAccountExistence(originId)
		if err != nil {
			return err
		}
		if !originExists {
			continue
		}
		comment, err := convertOpinionToComment(opinion, p)
		if err != nil {
			return err
		}

		if _, exist := commenters[originId]; !exist {
			commenters[originId] = true
			if err := migrateCommentOrigin(comment, opinion); err != nil {
				return err
			}
		}

		count++
	}
	p.RepliesCount += count
	return nil
}

// convertOpinionToComment first converts opinion to comment and persists it.
// Adds Relationship: JNewStatusUpdate -> reply    -> JComment
//                    JAccount         -> creator -> JComment
func convertOpinionToComment(opinion *Post, post *Post) (*Comment, error) {
	c := &Comment{
		Id:         helper.NewObjectId(),
		Body:       opinion.Body,
		OriginType: opinion.OriginType,
		OriginId:   opinion.OriginId,
		Meta:       opinion.Meta,
	}
	c.Meta.Likes = 0 // TODO not sure about it
	if err := helper.AddComment(c); err != nil {
		return c, err
	}

	// Add relationship: JNewStatusUpdate -> reply -> JComment
	r := &Relationship{
		Id:         helper.NewObjectId(),
		SourceId:   post.Id,
		SourceName: "JNewStatusUpdate",
		TargetId:   c.Id,
		TargetName: "JComment",
		As:         "reply",
		TimeStamp:  opinion.Meta.CreatedAt,
	}
	if err := helper.AddRelationship(r); err != nil {
		return c, err
	}
	return c, addCommentCreator(c, r)
}

// addCommentCreator inserts a new relationship as JAccount -> creator -> JComment
func addCommentCreator(c *Comment, r *Relationship) error {
	r.Id = helper.NewObjectId()
	r.SourceId = c.OriginId
	r.SourceName = "JAccount"
	r.As = "creator"
	r.TimeStamp = c.Meta.CreatedAt
	return helper.AddRelationship(r)
}

// migrateCommentOrigins inserts commenter and follower relationships
// JNewStatusUpdate -> commenter -> JAccount
// JNewStatusUpdate -> follower -> JAccount
func migrateCommentOrigin(c *Comment, p *Post) error {
	r := &Relationship{
		Id:         helper.NewObjectId(),
		SourceId:   p.Id,
		SourceName: "JNewStatusUpdate",
		TargetId:   c.OriginId,
		TargetName: "JAccount",
		As:         "commenter",
		TimeStamp:  c.Meta.CreatedAt,
	}
	if err := helper.AddRelationship(r); err != nil {
		return err
	}
	r.Id = helper.NewObjectId()
	r.As = "follower"
	return helper.AddRelationship(r)
}

func migrateOrigin(p *Post) error {
	r := &Relationship{
		Id:         helper.NewObjectId(),
		SourceId:   p.OriginId,
		SourceName: "JAccount",
		TargetId:   p.Id,
		TargetName: "JNewStatusUpdate",
		TimeStamp:  p.Meta.CreatedAt,
		As:         "creator",
	}
	if err := helper.AddRelationship(r); err != nil {
		return err
	}

	r = swapRelationship(r, "author")
	return helper.AddRelationship(r)
}

func verifyOrigin(p *Post) error {
	originId := p.OriginId.Hex()
	if originId == "" {
		return fmt.Errorf("Empty origin id")
	}

	result, err := helper.CheckAccountExistence(originId)
	if err != nil {
		return err
	}
	if !result {
		return fmt.Errorf("Origin not found - %v", originId)
	}

	return nil
}

// swapTagRelation swaps source and target data of relationships. It is used
// for converting bidirectional relationships.
func swapRelationship(r *Relationship, as string) *Relationship {
	return &Relationship{
		Id:         helper.NewObjectId(),
		As:         as,
		SourceId:   r.TargetId,
		SourceName: r.TargetName,
		TargetId:   r.SourceId,
		TargetName: r.SourceName,
		TimeStamp:  r.TimeStamp,
		Data:       r.Data,
	}
}
