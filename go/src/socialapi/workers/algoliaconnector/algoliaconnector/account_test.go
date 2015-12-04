package algoliaconnector

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"strconv"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAccountTesting(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake account", t, func() {
		acc, _, name := models.CreateRandomGroupDataWithChecks()
		So(name, ShouldNotBeNil)
		So(acc, ShouldNotBeNil)

		Convey("it should save the document to algolia", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)

			Convey("it should be able to fetch algolia data", func() {
				// make sure account is there
				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

				_, err = modelhelper.GetUser(acc.Nick)
				So(err, ShouldBeNil)

				// update user's email
				selector := bson.M{"username": acc.Nick}
				newEmail := "mehmetalixsavasx1x2x" + models.RandomGroupName() + "@koding.com"
				updateQuery := bson.M{"email": newEmail}

				err = modelhelper.UpdateUser(selector, updateQuery)
				So(err, ShouldBeNil)

				err = handler.AccountUpdated(acc)
				So(err, ShouldBeNil)

				index, err := handler.indexes.GetIndex(IndexAccounts)
				So(err, ShouldBeNil)

				params := make(map[string]interface{})
				record, err := index.Search("mehmetalixsavasx1x2x", params)
				So(err, ShouldBeNil)

				hist, ok := record.(map[string]interface{})["hits"]

				usernames := make([]string, 0)
				objects := make([]string, 0)

				if ok {
					hinter, ok := hist.([]interface{})
					if ok {
						for _, v := range hinter {
							val, k := v.(map[string]interface{})
							if k {
								object := val["objectID"].(string)
								value := val["nick"].(string)

								usernames = append(usernames, value)
								objects = append(objects, object)

								_, err = index.DeleteObject(object)
								So(err, ShouldBeNil)
							}

						}
					}
				}

				So(usernames, ShouldNotBeNil)
				So(objects, ShouldNotBeNil)

			})

			Convey("it should be able to fetch many account with given query", func() {
				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

				// we create 10 acc for algolia test
				for i := 0; i < 10; i++ {
					ac, _, _ := models.CreateRandomGroupDataWithChecks()

					err := handler.AccountCreated(ac)
					So(err, ShouldBeNil)

					selector := bson.M{"username": ac.Nick}
					newEmail := "mehmetali-test" + models.RandomGroupName() + "@koding.com"
					updateQuery := bson.M{"email": newEmail}
					err = modelhelper.UpdateUser(selector, updateQuery)
					So(err, ShouldBeNil)

					err = handler.AccountUpdated(ac)
					So(err, ShouldBeNil)
					time.Sleep(1 * time.Second)
				}

				//required for getting algolia datas correctly
				time.Sleep(5 * time.Second)

				_, err = modelhelper.GetUser(acc.Nick)
				So(err, ShouldBeNil)

				index, err := handler.indexes.GetIndex(IndexAccounts)
				So(err, ShouldBeNil)

				params := make(map[string]interface{})
				record, err := index.Search("mehmetali-test", params)
				So(err, ShouldBeNil)

				hist, ok := record.(map[string]interface{})["hits"]

				usernames := make([]string, 0)
				objects := make([]string, 0)

				if ok {
					hinter, ok := hist.([]interface{})
					if ok {
						for _, v := range hinter {
							val, k := v.(map[string]interface{})
							if k {
								object := val["objectID"].(string)
								value := val["nick"].(string)

								usernames = append(usernames, value)
								objects = append(objects, object)
							}

						}
					}
				}

				So(len(usernames), ShouldBeGreaterThan, 0)
				So(len(objects), ShouldBeGreaterThan, 0)

				Convey("it should be able to delete many account with given query", func() {

					So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

					for i := 0; i < 10; i++ {
						ac, _, _ := models.CreateRandomGroupDataWithChecks()

						err := handler.AccountCreated(ac)
						So(err, ShouldBeNil)

						selector := bson.M{"username": ac.Nick}
						newEmail := "mehmetali-test" + models.RandomGroupName() + "@koding.com"
						updateQuery := bson.M{"email": newEmail}
						err = modelhelper.UpdateUser(selector, updateQuery)
						So(err, ShouldBeNil)

						err = handler.AccountUpdated(ac)
						So(err, ShouldBeNil)
						time.Sleep(1 * time.Second)
					}

					time.Sleep(5 * time.Second)

					_, err = modelhelper.GetUser(acc.Nick)
					So(err, ShouldBeNil)

					_, err := handler.indexes.GetIndex(IndexAccounts)
					So(err, ShouldBeNil)

					usernames := make([]string, 0)
					objects := make([]string, 0)

					nbHits, _ := record.(map[string]interface{})["nbHits"]
					nbPages, _ := record.(map[string]interface{})["nbPages"]

					var pages float64 = nbPages.(float64)
					var nbHit float64 = nbHits.(float64)

					for pages > 0 && nbHit != 0 {
						record, err := index.Search("mehmetali-test", params)
						hist, ok := record.(map[string]interface{})["hits"]

						// fmt.Println("hist is :", hist)
						nbHits, _ := record.(map[string]interface{})["nbHits"]
						nbPages, _ := record.(map[string]interface{})["nbPages"]

						pages = nbPages.(float64)
						nbHit = nbHits.(float64)

						if ok {
							hinter, ok := hist.([]interface{})
							if ok {
								for _, v := range hinter {
									val, k := v.(map[string]interface{})
									if k {
										object := val["objectID"].(string)
										value := val["nick"].(string)

										usernames = append(usernames, value)
										objects = append(objects, object)
										_, err = index.DeleteObject(object)
										So(err, ShouldBeNil)
									}

								}
							}
						}
					}

					lenghtUsernames := len(usernames)
					lenghtObjects := len(objects)
					So(lenghtUsernames, ShouldBeGreaterThan, 10)
					So(lenghtObjects, ShouldBeGreaterThan, 10)

				})

				Convey("it should have delete algolia accounts", func() {
					fmt.Println("=============>>>>>>>>>>>>>>>>>>>")
					fmt.Println("=============>>>>>>>>>>>>>>>>>>>")
					fmt.Println("it should have delete algolia accounts")
					fmt.Println("=============>>>>>>>>>>>>>>>>>>>")
					fmt.Println("=============>>>>>>>>>>>>>>>>>>>")
					// make sure account is there
					So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

					for i := 0; i < 10; i++ {
						rand.Seed(time.Now().UnixNano())
						strconv.FormatInt(rand.Int63(), 10)
						name := "guter-" + strconv.FormatInt(rand.Int63(), 10)
						ac, _ := models.CreateAccountInBothDbsWithNick(name)

						err := handler.AccountCreated(ac)
						So(err, ShouldBeNil)

						selector := bson.M{"username": ac.Nick}
						newEmail := "mehmetali-test" + models.RandomGroupName() + "@koding.com"
						updateQuery := bson.M{"email": newEmail}
						err = modelhelper.UpdateUser(selector, updateQuery)
						So(err, ShouldBeNil)

						err = handler.AccountUpdated(ac)
						So(err, ShouldBeNil)
						time.Sleep(1 * time.Second)
					}

					time.Sleep(5 * time.Second)

					_, err = handler.indexes.GetIndex(IndexAccounts)
					So(err, ShouldBeNil)

					// record, _ := index.Search("mehmetalisa", map[string]interface{}{"restrictSearchableAttributes": "email"})
					// params := make(map[string]interface{})
					params := map[string]interface{}{"restrictSearchableAttributes": "nick"}
					record, _ := index.Search("guter-", params)

					hits, _ := record.(map[string]interface{})["nbHits"]
					hit := hits.(float64)
					So(hit, ShouldBeGreaterThan, 0)

					err = handler.DeleteNicksWithQuery("guter-")
					So(err, ShouldBeNil)

					// necessary for getting datas from algolia,
					time.Sleep(5 * time.Second)

					r, err := index.Search("guter-", params)
					So(err, ShouldBeNil)
					nbHits, _ := r.(map[string]interface{})["nbHits"]
					nbHit := nbHits.(float64)
					So(nbHit, ShouldBeLessThan, 10)
				})
			})
		})
	})
}

func TestAccountSaved(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake account", t, func() {
		acc, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc, ShouldNotBeNil)

		Convey("it should save the document to algolia", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)

			Convey("it should have email in it", func() {
				// make sure account is there
				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

				user, err := modelhelper.GetUser(acc.Nick)
				So(err, ShouldBeNil)

				err = makeSureWithSearch(
					handler,
					IndexAccounts,
					user.Email,
					map[string]interface{}{"restrictSearchableAttributes": "email"},
					func(record map[string]interface{}, err error) bool {
						if err != nil {
							return false
						}

						if record == nil {
							return false
						}

						hits, ok := record["nbHits"]
						if hits == nil || !ok {
							return false
						}

						if hits.(float64) <= 0 {
							return false
						}

						return true
					},
				)

				So(err, ShouldBeNil)
			})
		})

		Convey("saving same account to algolia should success", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)
			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
		})
	})
}

func TestAccountUpdated(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake account", t, func() {
		acc, err := models.CreateAccountInBothDbs()
		So(acc, ShouldNotBeNil)
		So(err, ShouldBeNil)

		Convey("it should save the document to algolia if not created before", func() {
			err := handler.AccountUpdated(acc)
			So(err, ShouldBeNil)

			Convey("it should have email in it", func() {
				// make sure account is there
				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

				// update user's email
				selector := bson.M{"username": acc.Nick}
				newEmail := models.RandomGroupName() + "@bar.com"
				updateQuery := bson.M{"email": newEmail}
				err = modelhelper.UpdateUser(selector, updateQuery)
				So(err, ShouldBeNil)

				err = handler.AccountUpdated(acc)
				So(err, ShouldBeNil)

				err = makeSureWithSearch(
					handler,
					IndexAccounts,
					newEmail,
					map[string]interface{}{"restrictSearchableAttributes": "email"},
					func(record map[string]interface{}, err error) bool {
						if err != nil {
							return false
						}

						if record == nil {
							return false
						}

						hits, ok := record["nbHits"]
						if hits == nil || !ok {
							return false
						}

						if hits.(float64) <= 0 {
							return false
						}

						return true
					})
				So(err, ShouldBeNil)
			})
		})

		Convey("updating the account again should sucess", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)
			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
		})

		Convey("it should delete the document when user account is deleted", func() {
			// first ensure account object is created
			err = handler.AccountCreated(acc)
			So(err, ShouldBeNil)
			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

			newNick := "guest-" + models.RandomName() + "-rm"
			err = models.UpdateUsernameInBothDbs(acc.Nick, newNick)
			So(err, ShouldBeNil)

			acc.Nick = newNick

			err = handler.AccountUpdated(acc)
			So(err, ShouldBeNil)

			So(doBasicTestForAccountDeletion(handler, acc.OldId), ShouldBeNil)

			Convey("deleting the account again should sucess", func() {
				err = handler.AccountUpdated(acc)
				So(err, ShouldBeNil)
				So(doBasicTestForAccountDeletion(handler, acc.OldId), ShouldBeNil)
			})
		})

		Convey("it should not return any error when deleted user does not exist on Algolia", func() {
			newNick := "guest-" + models.RandomName() + "-rm"
			err = models.UpdateUsernameInBothDbs(acc.Nick, newNick)
			So(err, ShouldBeNil)

			acc.Nick = newNick

			err = handler.AccountUpdated(acc)
			So(err, ShouldBeNil)

			So(doBasicTestForAccountDeletion(handler, acc.OldId), ShouldBeNil)
		})

	})
}

func TestAccountParticipantAdded(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some account", t, func() {
		acc, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc, ShouldNotBeNil)

		tc1 := models.CreateTypedGroupedChannelWithTest(
			acc.Id,
			models.Channel_TYPE_TOPIC,
			models.Channel_KODING_NAME,
		)

		models.AddParticipantsWithTest(tc1.Id, acc.Id)

		cp := &models.ChannelParticipant{
			ChannelId:      tc1.Id,
			AccountId:      acc.Id,
			StatusConstant: models.ChannelParticipant_STATUS_ACTIVE,
		}

		Convey("when the account is already on algolia", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)
			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

			err = handler.ParticipantCreated(cp)
			So(err, ShouldBeNil)

			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
			So(makeSureHasTag(handler, acc.OldId, strconv.FormatInt(tc1.Id, 10)), ShouldBeNil)

			Convey("trying to add again should success", func() {
				err = handler.ParticipantCreated(cp)
				So(err, ShouldBeNil)

				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
				So(makeSureHasTag(handler, acc.OldId, strconv.FormatInt(tc1.Id, 10)), ShouldBeNil)
				So(makeSureTagLen(handler, acc.OldId, 2), ShouldBeNil)
			})
		})

		Convey("when the account is not on algolia", func() {
			err = handler.ParticipantCreated(cp)
			So(err, ShouldBeNil)

			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
			So(makeSureHasTag(handler, acc.OldId, strconv.FormatInt(tc1.Id, 10)), ShouldBeNil)
			So(makeSureTagLen(handler, acc.OldId, 1), ShouldBeNil)
		})
	})
}

func TestAccountParticipantRemoved(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some account", t, func() {
		acc, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc, ShouldNotBeNil)

		tc1 := models.CreateTypedGroupedChannelWithTest(
			acc.Id,
			models.Channel_TYPE_TOPIC,
			models.Channel_KODING_NAME,
		)

		models.AddParticipantsWithTest(tc1.Id, acc.Id)

		cp := &models.ChannelParticipant{
			ChannelId:      tc1.Id,
			AccountId:      acc.Id,
			StatusConstant: models.ChannelParticipant_STATUS_ACTIVE,
		}

		Convey("when the account is already on algolia", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)
			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

			// add it to algolia
			err = handler.ParticipantCreated(cp)
			So(err, ShouldBeNil)

			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
			So(makeSureHasTag(handler, acc.OldId, strconv.FormatInt(tc1.Id, 10)), ShouldBeNil)
			So(makeSureTagLen(handler, acc.OldId, 2), ShouldBeNil)

			cp.StatusConstant = models.ChannelParticipant_STATUS_LEFT

			// now remove the tag
			err = handler.ParticipantUpdated(cp)
			So(err, ShouldBeNil)

			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
			So(makeSureTagLen(handler, acc.OldId, 1), ShouldBeNil)

			Convey("trying to update again should success", func() {
				err = handler.ParticipantUpdated(cp)
				So(err, ShouldBeNil)

				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)
				So(makeSureTagLen(handler, acc.OldId, 1), ShouldBeNil)
			})
		})

		Convey("when the account is not on algolia", func() {
			cp.StatusConstant = models.ChannelParticipant_STATUS_LEFT
			err = handler.ParticipantUpdated(cp)
			So(err, ShouldBeNil)

			Convey("trying to delete again should success", func() {
				err = handler.ParticipantUpdated(cp)
				So(err, ShouldBeNil)
			})
		})
	})
}

func doBasicTestForAccount(handler *Controller, id string) error {
	return makeSureAccount(handler, id, func(record map[string]interface{}, err error) bool {
		if err != nil {
			return false
		}

		// record map[string]interface {}{
		//     "nick":     "563a662f9bc22bbc62000001",
		//     "objectID": "563a662f9bc22bbc62000002",
		//     "_tags":    []interface {}{
		//         "6067437032240578561",
		//     },
		//     "firstName": "",
		//     "lastName":  "",
		// }
		if record == nil {
			return false
		}

		if record["objectID"] != id {
			return false
		}

		nick, ok := record["nick"].(string)
		if !ok {
			return false
		}

		if len(nick) == 0 {
			return false
		}

		// koding channel id should be there
		tagsInterface, ok := record["_tags"]
		if !ok {
			return false
		}

		tags, ok := tagsInterface.([]interface{})
		if !ok {
			return false
		}

		// koding channel id should be there
		if len(tags) < 1 {
			return false
		}

		// first name and last name can be empty

		return true
	})
}

func makeSureHasTag(handler *Controller, id string, tag string) error {
	return makeSureAccount(handler, id, func(record map[string]interface{}, err error) bool {
		if err != nil {
			return false
		}

		if record == nil {
			return false
		}

		// koding channel id should be there
		tagsInterface, ok := record["_tags"]
		if !ok {
			return false
		}

		tags, ok := tagsInterface.([]interface{})
		if !ok {
			return false
		}

		for _, tagI := range tags {
			tagS, ok := tagI.(string)
			if !ok {
				return false
			}

			if tagS == tag {
				return true
			}
		}

		return false
	})
}

func makeSureTagLen(handler *Controller, id string, tagLen int) error {
	return makeSureAccount(handler, id, func(record map[string]interface{}, err error) bool {
		if err != nil {
			return false
		}

		return checkTagLen(record, tagLen)
	})
}

func doBasicTestForAccountDeletion(handler *Controller, id string) error {
	return makeSureAccount(handler, id, func(record map[string]interface{}, err error) bool {
		if err == nil {
			return false
		}

		return true
	})
}

func checkTagLen(record map[string]interface{}, tagLen int) bool {
	if record == nil {
		return false
	}

	tagsInterface, ok := record["_tags"]
	if !ok {
		return false
	}

	tags, k := tagsInterface.([]interface{})
	if !k {
		return false
	}

	return len(tags) != tagLen
}
