package generator

import (
	"fmt"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"
	"testing"

	"github.com/koding/runner"

	"github.com/koding/redis"
	. "github.com/smartystreets/goconvey/convey"
)

var (
	r         *runner.Runner
	redisConn *redis.RedisSession
)

var (
	firstItem  *models.SitemapItem
	secondItem *models.SitemapItem
	thirdItem  *models.SitemapItem
)

const TESTFILE = "test"

func prepareItems() {
	firstItem = buildSitemapItem(models.TYPE_CHANNEL, models.STATUS_ADD)
	secondItem = buildSitemapItem(models.TYPE_CHANNEL, models.STATUS_ADD)
	thirdItem = buildSitemapItem(models.TYPE_CHANNEL, models.STATUS_ADD)
}

func TestSitemapGeneration(t *testing.T) {
	r = runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	redisConf := r.Conf
	redisConn = runner.MustInitRedisConn(redisConf)

	prepareItems()

	Convey("While testing sitemap generation", t, func() {

		Convey("controller should be able to created", func() {
			controller, err := New(r.Log, redisConn)
			So(err, ShouldBeNil)
			controller.fileName = TESTFILE
			Convey("As a crawler I want to read sitemaps", func() {
				Convey("when there is only one item", func() {
					Convey("an item must be added by feeder beforehand", func() {
						err := addSitemapItem(firstItem)
						So(err, ShouldBeNil)

						Convey("generator should be able to fetch item", func() {
							els, err := controller.fetchElements()
							So(err, ShouldBeNil)
							So(len(els), ShouldEqual, 1)

							Convey("generator should be able to group items within container", func() {
								container := controller.buildContainer(els)
								So(len(container.Add), ShouldEqual, 1)
								So(len(container.Delete), ShouldEqual, 0)
								So(len(container.Update), ShouldEqual, 0)

								hostname := appConfig.Hostname
								protocol := appConfig.Protocol
								location := fmt.Sprintf("%s//%s/Activity/%s", protocol, hostname, firstItem.Slug)
								So(container.Add[0].Location, ShouldEqual, location)
								Convey("item should be able to added to sitemap", func() {
									err = controller.updateFile(container)
									So(err, ShouldBeNil)
									sf := models.NewSitemapFile()
									err = sf.ByName(TESTFILE)
									So(err, ShouldBeNil)
									set, err := sf.UnmarshalBlob()
									So(err, ShouldBeNil)
									So(len(set.Definitions), ShouldEqual, 1)
								})
							})
						})

					})
				})
				Convey("second item should be able to appended to sitemap", func() {
					Convey("an item must be added by feeder beforehand", func() {
						err := addSitemapItem(secondItem)
						So(err, ShouldBeNil)
					})
					Convey("generator should be able to fetch item", func() {
						els, err := controller.fetchElements()
						So(err, ShouldBeNil)
						So(len(els), ShouldEqual, 1)

						Convey("item should be appended to current sitemap", func() {
							container := controller.buildContainer(els)
							err := controller.updateFile(container)
							So(err, ShouldBeNil)
							sf := models.NewSitemapFile()
							err = sf.ByName(TESTFILE)
							So(err, ShouldBeNil)
							currentSet, err := sf.UnmarshalBlob()
							So(err, ShouldBeNil)
							So(len(currentSet.Definitions), ShouldEqual, 2)
						})
					})
				})
				Convey("first item should be able to updated", func() {
					Convey("updated item must be added by feeder", func() {
						firstItem.Status = models.STATUS_UPDATE
						err := addSitemapItem(firstItem)
						So(err, ShouldBeNil)
					})
					Convey("generator should be able to fetch item", func() {
						els, err := controller.fetchElements()
						So(err, ShouldBeNil)
						So(len(els), ShouldEqual, 1)
						Convey("generator should be able to group items within container", func() {
							container := controller.buildContainer(els)
							So(len(container.Add), ShouldEqual, 0)
							So(len(container.Delete), ShouldEqual, 0)
							So(len(container.Update), ShouldEqual, 1)
							Convey("item should be updated in sitemap file", func() {
								err = controller.updateFile(container)
								So(err, ShouldBeNil)
								sf := models.NewSitemapFile()
								err = sf.ByName(TESTFILE)
								So(err, ShouldBeNil)
								currentSet, err := sf.UnmarshalBlob()
								So(err, ShouldBeNil)
								So(len(currentSet.Definitions), ShouldEqual, 2)
								So(currentSet.Definitions[0].LastModified, ShouldNotBeEmpty)
							})
						})
					})
					Convey("second item should be able to deleted", func() {
						Convey("deleted item must be added by feeder", func() {
							secondItem.Status = models.STATUS_DELETE
							err := addSitemapItem(secondItem)
							So(err, ShouldBeNil)
						})
						Convey("generator should be able to fetch item", func() {
							els, err := controller.fetchElements()
							So(err, ShouldBeNil)
							So(len(els), ShouldEqual, 1)
							Convey("generator should be able to group items within container", func() {
								container := controller.buildContainer(els)
								So(len(container.Add), ShouldEqual, 0)
								So(len(container.Delete), ShouldEqual, 1)
								So(len(container.Update), ShouldEqual, 0)
								Convey("item should be deleted from sitemap file", func() {
									err := controller.updateFile(container)
									So(err, ShouldBeNil)
									sf := models.NewSitemapFile()
									err = sf.ByName(TESTFILE)
									So(err, ShouldBeNil)
									currentSet, err := sf.UnmarshalBlob()
									So(err, ShouldBeNil)
									So(len(currentSet.Definitions), ShouldEqual, 1)
								})
							})
						})

					})
					Convey("items must be recovered in case of an error", func() {
						Convey("updated item must be added by feeder", func() {
							err := addSitemapItem(thirdItem)
							So(err, ShouldBeNil)
						})
						Convey("generator should be able to build container", func() {
							els, err := controller.fetchElements()
							So(err, ShouldBeNil)
							So(len(els), ShouldEqual, 1)
							controller.buildContainer(els)
							Convey("generator should be able to re-add to next queue in error case", func() {
								controller.handleError(els)
								key := common.PrepareNextFileNameSetCacheKey(int(controller.timeInterval.Minutes()))
								member, err := controller.redisConn.PopSetMember(key)
								So(err, ShouldBeNil)
								So(member, ShouldEqual, TESTFILE)
								key = common.PrepareNextFileCacheKey(TESTFILE, int(controller.timeInterval.Minutes()))
								member, err = controller.redisConn.PopSetMember(key)
								So(err, ShouldBeNil)
								So(member, ShouldNotBeNil)
							})
						})

					})
				})
			})
			Reset(func() {

				controller.Shutdown()
			})
		})

		Convey("We should be able to tear down suite", func() {
			sf := models.NewSitemapFile()
			err := sf.ByName(TESTFILE)
			So(err, ShouldBeNil)
			err = sf.Delete()
			So(err, ShouldBeNil)
		})
	})

	redisConn.Close()
}

func buildSitemapItem(typeConstant, status string) *models.SitemapItem {
	i := models.NewSitemapItem()
	i.Id = rand.Int63n(10000)
	i.TypeConstant = typeConstant
	i.Status = status
	i.Slug = fmt.Sprintf("%s-%d", i.TypeConstant, i.Id)

	return i
}

func createSitemapItem(id int64, typeConstant, status string) *models.SitemapItem {
	i := models.NewSitemapItem()
	i.Id = id
	i.TypeConstant = typeConstant
	i.Status = status

	return i
}

func addSitemapItem(i *models.SitemapItem) error {
	interval := common.GetInterval()
	key := common.PrepareCurrentFileCacheKey(TESTFILE, int(interval.Minutes()))
	value := i.PrepareSetValue()

	if _, err := redisConn.AddSetMembers(key, value); err != nil {
		return err
	}

	return nil
}
