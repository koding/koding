package topicfeed

import (
	"io/ioutil"
	"math/rand"
	"os"
	"path"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
	"launchpad.net/goyaml"
)

type Conformance struct {
	Tests map[string][]*Test
}

type Test struct {
	Expected interface{}
}

var cwd, _ = os.Getwd()
var extractYmlPath = path.Join(cwd, "tests.yml")

func TestExtractedTopicCanBeWrittenToDatabase(t *testing.T) {
	r := runner.New("TrollMode-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	rand.Seed(time.Now().UnixNano())
	groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

	a, err := createAccount()
	Convey("while extracting topics", t, func() {
		So(a, ShouldNotBeNil)
		So(err, ShouldBeNil)

		Convey("duplicates should be returned as unique", func() {
			contents, err := ioutil.ReadFile(extractYmlPath)
			So(err, ShouldBeNil)

			var conformance = &Conformance{}

			err = goyaml.Unmarshal(contents, &conformance)
			So(err, ShouldBeNil)

			hashtagTests, ok := conformance.Tests["hashtags"]
			So(ok, ShouldBeTrue)

			allHashTags := make(map[string]struct{})
			for _, test := range hashtagTests {
				expected, ok := test.Expected.([]interface{})
				So(ok, ShouldBeTrue)

				for _, e := range expected {
					hashtag := e.(string)
					if hashtag == "" {
						continue
					}

					allHashTags[hashtag] = struct{}{}
				}
			}
			for hashtag, _ := range allHashTags {
				c := models.NewChannel()
				c.CreatorId = a.Id
				c.GroupName = groupName
				c.Name = hashtag

				So(c.Create(), ShouldBeNil)

				c1 := models.NewChannel()
				So(c1.ById(c.Id), ShouldBeNil)
				So(c1.Name, ShouldEqual, c.Name)
			}
		})
	})
}

func createAccount() (*models.Account, error) {
	a := models.NewAccount()
	oldId := bson.NewObjectId()
	a.OldId = oldId.Hex()
	a.Nick = "acc" + strconv.Itoa(rand.Intn(10e6))
	if err := a.Create(); err != nil {
		return nil, err
	}
	return a, nil
}
