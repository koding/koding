package generator

import (
	"fmt"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"
	"testing"

	"github.com/koding/redis"
	. "github.com/smartystreets/goconvey/convey"
)

var (
	r          *runner.Runner
	controller *Controller
	redisConn  *redis.RedisSession
)

const TESTFILE = "test"

func TestSitemapGeneration(t *testing.T) {

	Convey("While testing sitemap generation", t, func() {
		Convey("We should be able to set up suite", func() {
			Convey("runner should be able to initialized", func() {
				r = runner.New("SitemapGeneratorTester")
				// test file helper can be added
				err := r.InitWithConfigFile("../../../../config/test.toml")
				So(err, ShouldBeNil)
			})
			Convey("redis should be able to initialized", func() {
				redisConf := r.Conf
				redisConn = helper.MustInitRedisConn(redisConf)

			})
			Convey("controller should be able to created", func() {
				var err error
				controller, err = New(r.Log)
				So(err, ShouldBeNil)
				controller.fileName = TESTFILE
			})
		})
		Convey("As a crawler I want to read sitemaps", func() {
			var els []*models.SitemapItem
			var container *models.ItemContainer
			var err error
			var firstItem *models.SitemapItem
			var secondItem *models.SitemapItem

			Convey("when there is only one item", func() {

				Convey("an item must be added by feeder beforehand", func() {
					firstItem = buildSitemapItem(models.TYPE_ACCOUNT, models.STATUS_ADD)

					err = addSitemapItem(firstItem)
					So(err, ShouldBeNil)
				})
				Convey("generator should be able to fetch item", func() {
					els, err = controller.fetchElements()
					So(err, ShouldBeNil)
					So(len(els), ShouldEqual, 1)
				})
				Convey("generator should be able to group items within container", func() {
					container = controller.buildContainer(els)
					So(len(container.Add), ShouldEqual, 1)
					So(len(container.Delete), ShouldEqual, 0)
					So(len(container.Update), ShouldEqual, 0)

					location := fmt.Sprintf("%s/%s", config.Get().Uri, firstItem.Slug)
					So(container.Add[0].Location, ShouldEqual, location)
				})
				Convey("item should be able to added to sitemap", func() {
					err = controller.updateFile(container)
					So(err, ShouldBeNil)
					sf := new(models.SitemapFile)
					err = sf.ByName(TESTFILE)
					So(err, ShouldBeNil)
					set, err := sf.UnmarshalBlob()
					So(err, ShouldBeNil)
					So(len(set.Definitions), ShouldEqual, 1)
				})
			})
			Convey("second item should be able to appended to sitemap", func() {
				Convey("an item must be added by feeder beforehand", func() {
					secondItem = buildSitemapItem(models.TYPE_ACCOUNT, models.STATUS_ADD)

					err = addSitemapItem(secondItem)
					So(err, ShouldBeNil)
				})
				Convey("generator should be able to fetch item", func() {
					els, err = controller.fetchElements()
					So(err, ShouldBeNil)
					So(len(els), ShouldEqual, 1)
				})
				Convey("item should be appended to current sitemap", func() {
					container = controller.buildContainer(els)
					err = controller.updateFile(container)
					So(err, ShouldBeNil)
					sf := new(models.SitemapFile)
					err = sf.ByName(TESTFILE)
					So(err, ShouldBeNil)
					currentSet, err := sf.UnmarshalBlob()
					So(err, ShouldBeNil)
					So(len(currentSet.Definitions), ShouldEqual, 2)
				})
			})
			Convey("first item should be able to updated", func() {
				Convey("updated item must be added by feeder", func() {
					firstItem.Status = models.STATUS_UPDATE
					err = addSitemapItem(firstItem)
					So(err, ShouldBeNil)
				})
				Convey("generator should be able to fetch item", func() {
					els, err = controller.fetchElements()
					So(err, ShouldBeNil)
					So(len(els), ShouldEqual, 1)
				})
				Convey("generator should be able to group items within container", func() {
					container = controller.buildContainer(els)
					So(len(container.Add), ShouldEqual, 0)
					So(len(container.Delete), ShouldEqual, 0)
					So(len(container.Update), ShouldEqual, 1)
				})
				Convey("item should be updated in sitemap file", func() {
					err = controller.updateFile(container)
					So(err, ShouldBeNil)
					sf := new(models.SitemapFile)
					err = sf.ByName(TESTFILE)
					So(err, ShouldBeNil)
					currentSet, err := sf.UnmarshalBlob()
					So(err, ShouldBeNil)
					So(len(currentSet.Definitions), ShouldEqual, 2)
					So(currentSet.Definitions[0].LastModified, ShouldNotBeEmpty)
				})
			})
			Convey("second item should be able to deleted", func() {
				Convey("deleted item must be added by feeder", func() {
					secondItem.Status = models.STATUS_DELETE
					err = addSitemapItem(secondItem)
					So(err, ShouldBeNil)
				})
				Convey("generator should be able to fetch item", func() {
					els, err = controller.fetchElements()
					So(err, ShouldBeNil)
					So(len(els), ShouldEqual, 1)
				})
				Convey("generator should be able to group items within container", func() {
					container = controller.buildContainer(els)
					So(len(container.Add), ShouldEqual, 0)
					So(len(container.Delete), ShouldEqual, 1)
					So(len(container.Update), ShouldEqual, 0)
				})
				Convey("item should be deleted from sitemap file", func() {
					err = controller.updateFile(container)
					So(err, ShouldBeNil)
					sf := new(models.SitemapFile)
					err = sf.ByName(TESTFILE)
					So(err, ShouldBeNil)
					currentSet, err := sf.UnmarshalBlob()
					So(err, ShouldBeNil)
					So(len(currentSet.Definitions), ShouldEqual, 1)
				})
			})
		})
		Convey("We should be able to tear down suite", func() {
			sf := new(models.SitemapFile)
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
	key := common.PrepareCurrentFileCacheKey(TESTFILE)
	value := i.PrepareSetValue()

	if _, err := redisConn.AddSetMembers(key, value); err != nil {
		return err
	}

	return nil
}
