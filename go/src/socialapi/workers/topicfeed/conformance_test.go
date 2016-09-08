package topicfeed

import (
	"math/rand"
	"os"
	"path"
	"socialapi/models"
	"strconv"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
	"gopkg.in/mgo.v2/bson"
	goyaml "gopkg.in/yaml.v2"
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

	groupName := models.RandomGroupName()

	a, err := createAccount()
	Convey("while extracting topics", t, func() {
		So(a, ShouldNotBeNil)
		So(err, ShouldBeNil)

		Convey("duplicates should be returned as unique", func() {
			var conformance = &Conformance{}

			err = goyaml.Unmarshal([]byte(conformanceTestsCases), &conformance)
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
