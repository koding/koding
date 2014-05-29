package main

import (
	"errors"
	"flag"
	"fmt"
	. "koding/db/models"
	helper "koding/db/mongodb/modelhelper"
	"koding/tools/config"

	"labix.org/v2/mgo/bson"
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

var (
	flagProfile        = flag.String("c", "", "Configuration profile from file")
	conf               *config.Config
	ErrAlreadyMigrated = errors.New("already migrated")
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf = config.MustConfig(*flagProfile)
	helper.Initialize(conf.Mongo)

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

		newId := helper.NewObjectId()
		oldId := post.Id

		oldPost := post
		post.Id = newId

		m.Index++
		if err := verifyOrigin(&post); err != nil {
			ReportError(m, err)
			continue
		}

		if err := insertNewStatusUpdate(&post, m); err != nil {
			ReportError(m, err)
			continue
		}

		newId = post.Id
		m.NewId = newId.Hex()

		if err := updatePostStatus(&oldPost, m, "Started"); err != nil {
			ReportError(m, err)
			continue
		}

		if err := migrateTags(&post, m); err != nil {
			ReportError(m, err)
			continue
		}

		if err := migrateOrigin(&post, m); err != nil {
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

		if err := updateName(&post); err != nil {
			ReportError(m, err)
			continue
		}

		if err := updatePostStatus(&oldPost, m, "Completed"); err != nil {
			ReportError(m, err)
			continue
		}

		// updates repliesCount
		su := post.ConvertToStatusUpdate()
		su.MigrationStatus = m.PostType
		if err := helper.UpdateStatusUpdate(su); err != nil {
			ReportError(m, err)
			continue
		}

		if err := fixRelationships(oldId, newId); err != nil {
			ReportError(m, err)
			continue
		}

		ReportSuccess(m)
	}
	return migrate(m)
}

func fixRelationships(oldId, newId bson.ObjectId) error {
	selector := helper.Selector{
		"targetId": oldId,
		"as": helper.Selector{
			"$in": []string{"like", "follower"},
		},
	}
	options := helper.Selector{
		"$set": helper.Selector{
			"targetId":   newId,
			"targetName": "JNewStatusUpdate",
		},
	}

	if err := helper.UpdateRelationships(selector, options); err != nil {
		return err
	}

	selector = helper.Selector{
		"sourceId": oldId,
		"as": helper.Selector{
			"$in": []string{"like", "follower"},
		},
	}
	options = helper.Selector{
		"$set": helper.Selector{
			"sourceId":   newId,
			"sourceName": "JNewStatusUpdate",
		},
	}

	if err := helper.UpdateRelationships(selector, options); err != nil {
		return err
	}

	return nil
}

func updatePostStatus(p *Post, m *Migrator, status string) error {
	p.MigrationStatus = status
	return helper.UpdatePost(p, m.PostType)
}

func updateRelationshipStatus(r Relationship, status string) {
	r.MigrationStatus = status
	helper.UpdateRelationship(&r)
}

func insertNewStatusUpdate(p *Post, m *Migrator) error {
	if p.MigrationStatus == "Completed" {
		return ErrAlreadyMigrated
	}
	// it seems post is already migrated with some incomplete relationships
	if p.MigrationStatus == "Started" {
		ep, err := helper.GetStatusUpdate(helper.Selector{"slug": p.Slug}, helper.Options{})
		p.Id = ep.Id
		return err
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
	// p.Meta.Likes = 0 // CtF: because we are not migrating activities it is reset

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
		content := ""
		// set markdown as syntax
		syntax := "markdown"

		codesnip, ok := p.Attachments[0]["content"]
		if ok {
			content = codesnip.(string)
		}
		language, ok := p.Attachments[0]["syntax"]
		if ok {
			syntax = language.(string)
		}

		codeBlock := fmt.Sprintf("```%s\n%s \n```", syntax, content)

		// concatenate post body with codesnip
		p.Body = fmt.Sprintf("%s \n\n%s \n", p.Body, codeBlock)

		p.Attachments = make([]map[string]interface{}, 0)
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
		// relationship already migrated
		if r.MigrationStatus == "Completed" {
			continue
		}
		tagId := r.TargetId.Hex()
		// first check tag existence
		exists, err := helper.CheckTagExistence(tagId)
		if err != nil {
			updateRelationshipStatus(r, "Error")
			return err
		}
		if !exists {
			updateRelationshipStatus(r, "Error")
			continue
		}
		or := r // copy old relationship
		// update tag relationships
		r.Id = helper.NewObjectId()
		r.SourceId = p.Id
		r.SourceName = "JNewStatusUpdate"
		if err := helper.AddRelationship(&r); err != nil {
			updateRelationshipStatus(or, "Error")
			return err
		}
		sr := swapRelationship(&r, "post") // CtF: leaking relationship
		if err := helper.AddRelationship(sr); err != nil {
			updateRelationshipStatus(or, "Error")
			return err
		}
		//append tag to status update body
		p.Body += fmt.Sprintf(" |#:JTag:%s|", tagId)
		updateRelationshipStatus(or, "Completed")
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
		or := r
		comment, err := helper.GetCommentById(r.TargetId.Hex())
		if err != nil {
			updateRelationshipStatus(or, "Error")
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
			updateRelationshipStatus(or, "Error")
			return accounts, err
		}
		if !originExists {
			updateRelationshipStatus(or, "Error")
			continue
		}
		if r.MigrationStatus != "Completed" {
			// add relationship: JNewStatusUpdate -> reply -> JComment
			r.Id = helper.NewObjectId()
			r.SourceId = p.Id
			r.SourceName = "JNewStatusUpdate"
			if err := helper.AddRelationship(&r); err != nil {
				updateRelationshipStatus(or, "Error")
				return accounts, err
			}

			// get unique commenters for each post
			if _, exist := accounts[originId]; !exist {
				accounts[originId] = true
				if err := migrateCommentOrigin(comment, p, m); err != nil {
					return accounts, err
				}
			}
			updateRelationshipStatus(or, "Completed")
		} else {
			accounts[originId] = true
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
		or := r
		opinion, err := helper.GetOpinionById(r.TargetId.Hex())
		if err != nil {
			updateRelationshipStatus(or, "Error")
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
			updateRelationshipStatus(or, "Error")
			return err
		}
		if !originExists {
			continue
		}
		if r.MigrationStatus != "Completed" {
			comment, err := convertOpinionToComment(opinion, p)
			if err != nil {
				updateRelationshipStatus(or, "Error")
				return err
			}
			if _, exist := commenters[originId]; !exist {
				commenters[originId] = true
				if err := migrateCommentOrigin(comment, p, m); err != nil {
					return err
				}
			}
			updateRelationshipStatus(or, "Completed")
		} else {
			commenters[originId] = true
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
func migrateCommentOrigin(c *Comment, p *Post, m *Migrator) error {
	s := helper.Selector{
		"sourceId": helper.GetObjectId(m.Id),
		"targetId": c.OriginId,
		"as":       "commenter",
	}
	r, err := helper.GetRelationship(s)
	if err != nil {
		return fmt.Errorf("commenter not found")
	}
	if r.MigrationStatus != "Completed" {
		or := r
		r.Id = helper.NewObjectId()
		r.SourceId = p.Id
		r.SourceName = "JNewStatusUpdate"
		if err := helper.AddRelationship(&r); err != nil {
			updateRelationshipStatus(or, "Error")
			return err
		}
		updateRelationshipStatus(or, "Completed")
	}

	return nil
}

func migrateOrigin(p *Post, m *Migrator) error {
	s := helper.Selector{
		"as":       "creator",
		"targetId": helper.GetObjectId(m.Id),
		"sourceId": p.OriginId,
	}
	r, err := helper.GetRelationship(s)
	if err != nil {
		return fmt.Errorf("creator not found")
	}

	if r.MigrationStatus != "Completed" {
		or := r
		r.Id = helper.NewObjectId()
		r.TargetId = p.Id
		r.TargetName = "JNewStatusUpdate"
		if err := helper.AddRelationship(&r); err != nil {
			updateRelationshipStatus(or, "Error")
			return err
		}
		updateRelationshipStatus(or, "Completed")
	}
	s = helper.Selector{
		"as":       "author",
		"sourceId": helper.GetObjectId(m.Id),
		"targetId": p.OriginId,
	}
	r, err = helper.GetRelationship(s)
	if err != nil {
		return fmt.Errorf("author not found")
	}

	if r.MigrationStatus != "Completed" {
		or := r
		r.Id = helper.NewObjectId()
		r.SourceId = p.Id
		r.SourceName = "JNewStatusUpdate"
		if err := helper.AddRelationship(&r); err != nil {
			updateRelationshipStatus(or, "Error")
			return err
		}
		updateRelationshipStatus(or, "Completed")
	}

	return nil
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

func updateName(p *Post) error {
	slug := Slug{
		ConstructorName: "JNewStatusUpdate",
		CollectionName:  "jNewStatusUpdates",
		UsedAsPath:      "slug",
		Group:           p.Group,
		Slug:            p.Slug,
	}
	name := &Name{
		Name:  fmt.Sprintf("Activity/%s", p.Slug),
		Slugs: []Slug{slug},
	}
	return helper.UpdateName(name)
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
