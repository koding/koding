package message

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
	"github.com/koding/runner"
)

var publicChannel *models.Channel

func Create(u *url.URL, h http.Header, req *models.ChannelMessage, c *models.Context) (int, http.Header, interface{}, error) {

	channelId, err := fetchInitialChannelId(u, c)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// override message type
	// all of the messages coming from client-side
	// should be marked as POST
	req.TypeConstant = models.ChannelMessage_TYPE_POST

	req.InitialChannelId = channelId

	if req.Payload == nil {
		req.Payload = gorm.Hstore{}
	}

	if c.Client.Account.ShareLocation {
		// gets the IP of the Client
		// and adds it to the payload of the ChannelMessage
		record, err := helper.MustGetGeoIPDB().City(c.Client.IP)
		if err != nil {
			runner.MustGetLogger().Error("errr while parsing ip, err :%s", err.Error())
		}

		if record.City.Names["en"] != "" {
			ll := fmt.Sprintf("%v , %v", record.City.Names["en"], record.Country.Names["en"])
			req.Payload["location"] = &ll
		} else {
			ll := fmt.Sprintf("%v", record.Country.Names["en"])
			req.Payload["location"] = &ll
		}

	}

	if err := checkThrottle(channelId, req.AccountId); err != nil {
		return response.NewBadRequest(err)
	}

	if err := req.Create(); err != nil {
		// todo this should be internal server error
		return response.NewBadRequest(err)
	}

	cml := models.NewChannelMessageList()
	// override channel id
	cml.ChannelId = channelId
	cml.MessageId = req.Id
	cml.ClientRequestId = req.ClientRequestId
	if err := cml.Create(); err != nil {
		// todo this should be internal server error
		return response.NewBadRequest(err)
	}

	cmc := models.NewChannelMessageContainer()
	err = cmc.Fetch(req.Id, request.GetQuery(u))

	// assign client request id back to message response because
	// client uses it for latency compansation
	cmc.Message.ClientRequestId = req.ClientRequestId
	return response.HandleResultAndError(cmc, err)
}

func fetchInitialChannelId(u *url.URL, context *models.Context) (int64, error) {
	channelId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return 0, err
	}

	c, err := models.ChannelById(channelId)
	if err != nil {
		return 0, err
	}

	// when somebody posts on a topic channel, for creating it both in public and topic channels
	// initialChannelId must be set as current group's public channel id
	if c.TypeConstant != models.Channel_TYPE_TOPIC {
		return channelId, nil
	}

	return fetchPublicChannelId(context.GroupName)
}

// TODO when we implement Team product, we will need a better caching mechanism
func fetchPublicChannelId(groupName string) (int64, error) {

	if groupName == "koding" && publicChannel != nil {
		return publicChannel.Id, nil
	}

	channel := models.NewChannel()
	if groupName == "koding" {
		publicChannel = channel
	}

	if err := channel.FetchPublicChannel(groupName); err != nil {
		return 0, err
	}

	return channel.Id, nil
}

func checkThrottle(channelId, requesterId int64) error {
	c, err := models.ChannelById(channelId)
	if err != nil {
		return err
	}

	if c.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	cm := models.NewChannelMessage()

	conf := config.MustGet()

	// if oit is defaul treturn  early
	if conf.Limits.PostThrottleDuration == "" {
		return nil
	}

	// if throttle count is zero, it meands it is not set
	if conf.Limits.PostThrottleCount == 0 {
		return nil
	}

	dur, err := time.ParseDuration(conf.Limits.PostThrottleDuration)
	if err != nil {
		return err
	}

	// subtrack duration from current time
	prevTime := time.Now().UTC().Truncate(dur)

	// count sends positional parameters, no need to sanitize input
	count, err := bongo.B.Count(
		cm,
		"initial_channel_id = ? and "+
			"account_id = ? and "+
			"created_at > ?",
		channelId,
		requesterId,
		prevTime.Format(time.RFC3339Nano),
	)
	if err != nil {
		return err
	}

	if count > conf.Limits.PostThrottleCount {
		return fmt.Errorf("reached to throttle, current post count %d for user %d", count, requesterId)
	}

	return nil
}

func Delete(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	cm := models.NewChannelMessage()
	cm.Id = id

	if err := cm.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	// if this is a reply no need to delete it's replies
	if cm.TypeConstant == models.ChannelMessage_TYPE_REPLY {
		mr := models.NewMessageReply()
		mr.ReplyId = id
		parent, err := mr.FetchParent()
		if err != nil {
			return response.NewBadRequest(err)
		}

		// delete the message here
		err = cm.DeleteMessageAndDependencies(false)
		// then invalidate the cache of the parent message
		bongo.B.AddToCache(parent)

	} else {
		err = cm.DeleteMessageAndDependencies(true)
	}

	if err != nil {
		return response.NewBadRequest(err)
	}

	// yes it is deleted but not removed completely from our system
	return response.NewDeleted()
}

func Update(u *url.URL, h http.Header, req *models.ChannelMessage) (int, http.Header, interface{}, error) {
	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	body := req.Body
	payload := req.Payload
	if err := req.ById(id); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	if req.Id == 0 {
		return response.NewBadRequest(err)
	}

	req.Body = body
	req.Payload = payload
	if err := req.Update(); err != nil {
		return response.NewBadRequest(err)
	}

	cmc := models.NewChannelMessageContainer()
	return response.HandleResultAndError(cmc, cmc.Fetch(id, request.GetQuery(u)))
}

func Get(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	cm, err := getMessageByUrl(u)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if cm.Id == 0 {
		return response.NewNotFound()
	}

	cmc := models.NewChannelMessageContainer()
	return response.HandleResultAndError(cmc, cmc.Fetch(cm.Id, request.GetQuery(u)))
}

func getMessageByUrl(u *url.URL) (*models.ChannelMessage, error) {

	// TODO
	// fmt.Println(`
	// 	------->
	//             ADD SECURTY CHECK FOR VISIBILTY OF THE MESSAGE
	//                         FOR THE REQUESTER
	//     ------->"`,
	// )

	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return nil, err
	}

	// get url query params
	q := request.GetQuery(u)

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"id": id,
		},
		Pagination: *bongo.NewPagination(1, 0),
	}

	cm := models.NewChannelMessage()
	// add exempt info
	query.AddScope(models.RemoveTrollContent(cm, q.ShowExempt))

	if err := cm.One(query); err != nil {
		return nil, err
	}

	return cm, nil
}

func GetWithRelated(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	cm, err := getMessageByUrl(u)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if cm.Id == 0 {
		return response.NewNotFound()
	}

	q := request.GetQuery(u)

	cmc := models.NewChannelMessageContainer()
	if err := cmc.Fetch(cm.Id, q); err != nil {
		return response.NewBadRequest(err)
	}

	cmc.AddIsInteracted(q).AddIsFollowed(q)

	return response.HandleResultAndError(cmc, cmc.Err)
}

func GetBySlug(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := request.GetQuery(u)

	if q.Slug == "" {
		return response.NewBadRequest(errors.New("slug is not set"))
	}

	cm := models.NewChannelMessage()
	if err := cm.BySlug(q); err != nil {
		if err == bongo.RecordNotFound {
			return response.NewNotFound()
		}
		return response.NewBadRequest(err)
	}

	cmc := models.NewChannelMessageContainer()
	if err := cmc.Fetch(cm.Id, q); err != nil {
		return response.NewBadRequest(err)
	}

	cmc.AddIsInteracted(q).AddIsFollowed(q)

	return response.HandleResultAndError(cmc, cmc.Err)
}
