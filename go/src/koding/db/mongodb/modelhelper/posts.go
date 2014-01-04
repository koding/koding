package modelhelper

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
)

var PostCollMap = map[string]string{
	"NewStatusUpdate": "jNewStatusUpdates",
	"StatusUpdate":    "jStatusUpdates",
	"BlogPost":        "jBlogPosts",
	"Discussion":      "jDiscussions",
	"CodeSnip":        "jCodeSnips",
	"Tutorial":        "jTutorials",
}

func GetPostById(id string, postType string) (*models.Post, error) {
	post := new(models.Post)
	coll, err := getPostType(postType)
	if err != nil {
		return post, err
	}
	return post, mongodb.One(coll, id, post)
}

func UpdatePost(p *models.Post, postType string) error {
	query := updateByIdQuery(p.Id.Hex(), p)
	return runQuery(postType, query)
}

func DeletePostById(id string, postType string) error {
	query := deleteByIdQuery(id)
	return runQuery(postType, query)
}

func GetSomePosts(s Selector, o Options, postType string) ([]models.Post, error) {
	posts := make([]models.Post, 0)
	query := func(c *mgo.Collection) error {
		q := c.Find(s)
		decorateQuery(q, o)
		return q.All(&posts)
	}
	return posts, runQuery(postType, query)
}

func CountPosts(s Selector, o Options, postType string) (int, error) {
	var count int
	query := countQuery(s, o, &count)
	return count, runQuery(postType, query)
}

func getPostType(postType string) (string, error) {
	coll, ok := PostCollMap[postType]
	if !ok {
		return coll, fmt.Errorf("Incorrect Post Type: %s", postType)
	}
	return coll, nil
}

func runQuery(postType string, query func(c *mgo.Collection) error) error {
	coll, err := getPostType(postType)
	if err != nil {
		return err
	}
	return mongodb.Run(coll, query)
}
