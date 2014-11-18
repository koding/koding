package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"time"

	"github.com/koding/bongo"

	"github.com/koding/logging"
)

var log logging.Logger

func main() {
	r := runner.New("Topic Migrator")
	if err := r.Init(); err != nil {
		fmt.Println(err)
	}
	defer r.Close()

	log = r.Log

	findTopics()

}

func findTopics() {
	c, err := fetchPublicChannel()
	if err != nil {
		log.Fatal("Could not fetch public koding channel")
	}

	t := time.Time{}
	rows, err := bongo.B.DB.Raw(
		`SELECT id
			FROM   channel_message
			WHERE  type_constant = 'post'
			AND    deleted_at = ?
			       AND id NOT IN (SELECT message_id
			                      FROM   channel_message_list
			                      WHERE  channel_id = ?)
			       AND initial_channel_id IN (SELECT id
			                                  FROM   channel
			                                  WHERE  group_name = 'koding'
			                                         AND type_constant = 'topic')
`, t, c.Id).Rows()
	if err != nil {
		log.Fatal("Could not fetch related data: %s", err)
	}

	var id int64
	for rows.Next() {
		if err := rows.Scan(&id); err != nil {
			log.Error("Could not fetch id: %s", err)
			continue
		}
		cml := models.NewChannelMessageList()
		query := &bongo.Query{
			Selector: map[string]interface{}{
				"message_id": id,
			},
		}

		if err := cml.One(query); err != nil {
			log.Error("Could not fetch channel message list: %s", err)
			continue
		}
		newCml := models.NewChannelMessageList()
		*newCml = *cml
		newCml.Id = 0
		newCml.ChannelId = c.Id

		if err := newCml.CreateRaw(); err != nil {
			log.Error("Could not create channel message list for message %d: %s", cml.MessageId, err)
		}
	}

}

func fetchPublicChannel() (*models.Channel, error) {
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":    "koding",
			"name":          "public",
			"type_constant": "group",
		},
	}

	c := models.NewChannel()
	err := c.One(q)
	if err != nil {
		return nil, err
	}

	return c, nil
}
