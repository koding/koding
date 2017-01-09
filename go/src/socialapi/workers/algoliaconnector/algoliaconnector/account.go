package algoliaconnector

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"os"
	"os/signal"
	"socialapi/models"
	"strconv"
	"strings"
	"sync"

	mgo "gopkg.in/mgo.v2"
)

// AccountCreated adds user the algolia and adds koding group's channel id
func (f *Controller) AccountCreated(data *models.Account) error {
	cleanupGuest := false
	return f.handleAccount(data, cleanupGuest, addUniqueTagMap(f.kodingChannelId))
}

// AccountCreated updates the user on algolia and adds koding group's channel id
func (f *Controller) AccountUpdated(data *models.Account) error {
	cleanupGuest := true
	return f.handleAccount(data, cleanupGuest, addUniqueTagMap(f.kodingChannelId))
}

// ParticipantUpdated operates with the participant deleted/created events, adds
// to algolia if the state is active, else removes from algolia
func (f *Controller) ParticipantUpdated(p *models.ChannelParticipant) error {
	return f.handleParticipantOperation(p)
}

// ParticipantCreated operates with the participant createad event, adds new tag
// to the algolia document
func (f *Controller) ParticipantCreated(p *models.ChannelParticipant) error {
	return f.handleParticipantOperation(p)
}

func (f *Controller) handleParticipantOperation(p *models.ChannelParticipant) error {
	if p.ChannelId == 0 {
		f.log.Info("channel id is 0, data: %+v", p)
		return nil
	}

	if p.AccountId == 0 {
		f.log.Info("account id is 0, data: %+v", p)
		return nil
	}

	// fetch account from database
	a := models.NewAccount()
	if err := a.ById(p.AccountId); err != nil {
		f.log.Error("err while fetching account: %s", err.Error())
		return nil
	}

	if a.Id == 0 {
		f.log.Critical("account found but id is 0 %+v", a)
		return nil
	}

	channelId := strconv.FormatInt(p.ChannelId, 10)
	if channelId == "" {
		f.log.Error("Channel Participant has malformed data %+v", p)
		return nil
	}

	tagMap := addUniqueTagMap(channelId) // as default add the new channel to tags

	// if status of the participant is not active remove it from user
	if p.StatusConstant != models.ChannelParticipant_STATUS_ACTIVE {
		tagMap = removeTagMap(channelId)
	}

	cleanupGuest := true
	return f.handleAccount(a, cleanupGuest, tagMap)
}

func (f *Controller) handleAccount(data *models.Account, cleanupGuest bool, tagMap map[string]interface{}) error {
	// do not send guests to algolia
	if strings.HasPrefix(data.Nick, "guest-") {
		if cleanupGuest {
			return f.delete(IndexAccounts, data.OldId)
		}

		return nil
	}

	user, err := modelhelper.GetUser(data.Nick)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		f.log.Error("user %+v is not found in mongodb", data)
		return nil
	}

	mongoaccount, err := modelhelper.GetAccount(data.Nick)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		f.log.Error("account %+v is not found in mongodb", data)
		return nil
	}

	return f.partialUpdate(IndexAccounts, map[string]interface{}{
		"objectID":  data.OldId,
		"nick":      data.Nick,
		"email":     user.Email,
		"firstName": mongoaccount.Profile.FirstName,
		"lastName":  mongoaccount.Profile.LastName,
		"_tags":     tagMap,
	})
}

func addUniqueTagMap(value string) map[string]interface{} {
	return map[string]interface{}{
		"_operation": "AddUnique",
		"value":      value,
	}
}

func removeTagMap(value string) map[string]interface{} {
	return map[string]interface{}{
		"_operation": "Remove",
		"value":      value,
	}
}

func (f *Controller) RemoveGuestAccounts() error {
	index, err := f.indexes.GetIndex(IndexAccounts)
	if err != nil {
		return err
	}

	res, err := index.DeleteByQuery("guest-", map[string]interface{}{})
	if err != nil {
		if res != nil {
			f.log.Error("Could not remove guest accounts from algolia: %+v \n", res)
		}
		return err
	}

	return nil
}

func (f *Controller) DeleteNicksWithQuery(queryName string) error {
	index, err := f.indexes.GetIndex(IndexAccounts)
	params := map[string]interface{}{"restrictSearchableAttributes": "nick"}
	record, err := index.Search(queryName, params)
	if err != nil {
		return err
	}

	var nbHit float64
	var pages float64

	nbHits, ok := record.(map[string]interface{})["nbHits"]
	if ok {
		nbHit = nbHits.(float64)
	}

	nbPages, ok := record.(map[string]interface{})["nbPages"]
	if ok {
		pages = nbPages.(float64)
	}

	for pages > 0 && nbHit != 0 {
		record, err := index.Search(queryName, params)
		hist, ok := record.(map[string]interface{})["hits"]

		nbHits, _ := record.(map[string]interface{})["nbHits"]
		nbPages, _ := record.(map[string]interface{})["nbPages"]
		pages = nbPages.(float64)
		nbHit = nbHits.(float64)

		index, err := f.indexes.GetIndex(IndexAccounts)
		if err != nil {
			return err
		}

		record, err = index.Search(queryName, params)
		if err != nil {
			return err
		}

		hist, ok = record.(map[string]interface{})["hits"]

		if ok {
			hinter, ok := hist.([]interface{})
			if ok {
				for _, v := range hinter {
					val, k := v.(map[string]interface{})
					if k {
						// value := val["nick"].(string)
						object := val["objectID"].(string)
						_, err := modelhelper.GetAccountById(object)
						if err != nil && err != modelhelper.ErrNotFound {
							return err
						}
						if err == modelhelper.ErrNotFound {
							if _, err = index.DeleteObject(object); err != nil {
								return nil
							}
						}
					}
				}
			}
		}
	}

	return nil

}

func (f *Controller) FetchIdOfNicksWithQuery(queryName string) ([]string, error) {

	index, err := f.indexes.GetIndex(IndexAccounts)
	if err != nil {
		return nil, err
	}
	params := map[string]interface{}{"restrictSearchableAttributes": "nick"}
	record, _ := index.Search(queryName, params)

	hist, ok := record.(map[string]interface{})["hits"]

	objects := make([]string, 0)
	if ok {

		hinter, ok := hist.([]interface{})
		if ok {
			for _, v := range hinter {
				val, k := v.(map[string]interface{})
				if k {
					value := val["nick"].(string)
					object := val["objectID"].(string)
					if strings.HasPrefix(value, queryName) {
						objects = append(objects, object)
					}
				}
			}
		}
	}
	return objects, nil
}

func (f *Controller) deleteAllGuestNicks(indexName string, objectIDs []string) error {
	for _, val := range objectIDs {
		if err := f.delete(indexName, val); err != nil {
			return err
		}
	}

	return nil
}

func (f *Controller) DeleteNicksWithQueryBrowseAll(queryName string) error {
	index, err := f.indexes.GetIndex(IndexAccounts)
	params := map[string]interface{}{
		"restrictSearchableAttributes": "nick",
	}
	record, err := index.Search(queryName, params)
	if err != nil {
		return err
	}

	workChan := make(chan string, 30)
	var wg sync.WaitGroup

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			<-signals
			close(workChan)
		}
	}()

	worker := func(objectID string) {
		_, err := modelhelper.GetAccountById(objectID)
		if err != nil && err != modelhelper.ErrNotFound {
			fmt.Println("err.Error() for objectID-->", err.Error(), objectID)
		}
		if err == modelhelper.ErrNotFound {
			fmt.Println("deleting object", objectID)
			if _, err = index.DeleteObject(objectID); err != nil {
				fmt.Println("deleting err.Error() for objectID-->", err.Error(), objectID)
			}
		}
	}

	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func(i int) {
			for id := range workChan {
				worker(id)
			}
			wg.Done()
		}(i)
	}

	params = map[string]interface{}{
		"restrictSearchableAttributes": "nick",
		"page":        3000,
		"hitsPerPage": 50,
	}

	counter := 0
	recordBrowse, err := index.BrowseAll(params)
	for {
		record, err = recordBrowse.Next()
		if err != nil {
			fmt.Println("ERROR:", err)
			return nil
		}
		counter++

		object, ok := record.(map[string]interface{})
		if ok {
			objectID := object["objectID"].(string)
			fmt.Println("counter, objectID-->", counter, objectID)
			workChan <- objectID
		}
	}
	fmt.Println("waiting for workers-->")

	wg.Wait()

	return nil

}
