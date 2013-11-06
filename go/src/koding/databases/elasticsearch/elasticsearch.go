package elasticsearch

// this file is created by Aybars, but i am committing it :)

// cd go && export GOPATH=`pwd`
// go get github.com/mattbaird/elastigo

import (
	"encoding/json"
	"fmt"
	"github.com/mattbaird/elastigo/api"
	"github.com/mattbaird/elastigo/core"
	"koding/workers/neo4jfeeder/mongohelper"
	"log"
	"os"
	"strings"
)

var NotAllowedNames = map[string]bool{
	"CStatusActivity":          true,
	"CFolloweeBucketActivity":  true,
	"CFollowerBucketActivity":  true,
	"CCodeSnipActivity":        true,
	"CDiscussionActivity":      true,
	"CReplieeBucketActivity":   true,
	"CReplierBucketActivity":   true,
	"CBlogPostActivity":        true,
	"CNewMemberBucketActivity": true,
	"CTutorialActivity":        true,
	"CLikeeBucketActivity":     true,
	"CLikerBucketActivity":     true,
	"CInstalleeBucketActivity": true,
	"CInstallerBucketActivity": true,
	"CActivity":                true,
	"CRunnableActivity":        true,
	"JAppStorage":              true,
	"JFeed":                    true,
}

var CollectionToESType = map[string]string{
	"JStatusUpdate":   "posts",
	"JBlogPost":       "posts",
	"JCodeSnip":       "posts",
	"JDiscussion":     "posts",
	"JTutorial":       "posts",
	"JAccount":        "accounts",
	"JTag":            "tags",
	"JUnifiedMessage": "unifiedmessages",
}

type Tag struct {
	Name  string `json:"name"`
	Id    string `json:"id"`
	Group string `json:"group"`
	Title string `json:"title"`
	Slug  string `json:"slug"`
}

type Origin struct {
	Name string `json:"name"`
	Id   string `json:"id"`
	Slug string `json:"slug"`
}

type Recipient struct {
	Name string `json:"name"`
	Id   string `json:"id"`
	Slug string `json:"slug"`
}

type Controller struct{}

type Attacher func(sourceName, sourceId, targetName, targetId string, sourceContent, targetContent map[string]interface{})

var Attachers = map[string]Attacher{
	"tagged":    AttachTag,
	"author":    AttachAuthor,
	"posted_by": AttachOrigin,
	"posted_to": AttachReceipent,
}

func CheckIfEligible(sourceName, targetName string) bool {
	notAllowedSuffixes := []string{
		"Bucket",
		"BucketActivity",
	}

	if NotAllowedNames[sourceName] || NotAllowedNames[targetName] {
		return false
	}

	for _, name := range notAllowedSuffixes {
		if strings.HasSuffix(sourceName, name) {
			return false
		}

		if strings.HasSuffix(targetName, name) {
			return false
		}
	}

	return true
}

/**
* returns type name for ES from given MongoDB.collectionName
* if it doesnt exists, in mapping returns collectionName
 */
func GetTypeName(collectionName string) string {
	typeName, ok := CollectionToESType[collectionName]
	if !ok {
		return collectionName
	}
	return typeName
}

// gets node from ES with given unique node id
// response will be object
func Get(index, _type, id string) (map[string]interface{}, error) {
	resp, err := core.Get(true, index, GetTypeName(_type), id)
	if err != nil {
		return nil, err
	}
	return resp.Source.(map[string]interface{}), nil
}

/*
The update API also support passing a partial document
curl -XPOST 'localhost:9200/test/type1/1/_update' -d '{
    "doc" : {
        "name" : "new_name"
    }
}'
*/
func Upsert(index string, _type string, id string, data map[string]interface{}) (api.BaseResponse, error) {
	var url string
	var retval api.BaseResponse
	url = fmt.Sprintf("/%s/%s/%s/_update", index, GetTypeName(_type), id)
	doc := map[string]interface{}{
		"doc": data,
	}

	postData, err := json.Marshal(doc)
	if err != nil {
		return retval, err
	}

	body, err := api.DoCommand("POST", url, string(postData))
	if err != nil {
		fmt.Println(err)
		os.Stdout.Write(body)
		panic(err)
		return retval, err
	}
	if err == nil {
		// marshall into json
		jsonErr := json.Unmarshal(body, &retval)
		if jsonErr != nil {
			return retval, jsonErr
		}
	}
	return retval, err
}

func Exists(index, _type, id string) (exists bool) {
	var url string
	var response map[string]interface{}

	if len(_type) > 0 {
		url = fmt.Sprintf("/%s/%s/%s", index, _type, id)
	} else {
		url = fmt.Sprintf("/%s/%s", index, id)
	}

	req, _ := api.ElasticSearchRequest("GET", url)
	httpStatusCode, _, err := req.Do(&response)

	if err != nil {
		fmt.Println("error from req.Do -", err)
		panic(err)
	}

	if httpStatusCode == 200 || httpStatusCode == 304 {
		return true
	}
	return false
}

/**
* this drops index, unless you know what you are doing, you shouldnt use this
* as it will delete everything in ES/
$ curl -XDELETE 'http://localhost:9200/twitter/'
**/
func DropIndex(index string) (bool, error) {
	url := fmt.Sprintf("/%s", index)
	var response map[string]interface{}
	req, _ := api.ElasticSearchRequest("DELETE", url)
	httpStatusCode, _, _ := req.Do(&response)
	if httpStatusCode == 200 || httpStatusCode == 304 {
		return true, nil
	}
	return false, nil
}

// updates/upserts node with given data
func IndexNode(id string, collection string, data map[string]interface{}) map[string]interface{} {
	// we check if the document is there, so we just update it partially,
	exists := Exists("koding", GetTypeName(collection), id)
	if !exists {
		// document doesnt exists.. lets create
		response, err := core.Index(true, "koding", GetTypeName(collection), id, data)
		log.Println(response)
		log.Println("err >>>>> err >>>", err)
	} else {
		// just update me...
		Upsert("koding", GetTypeName(collection), id, data)
	}

	return nil
}

func DeleteNode(id, collectionName string) bool {
	result, _ := core.Delete(false, "koding", GetTypeName(collectionName), id, 1, "")
	return result.Ok
}

func GetRecipientsFromDocument(data map[string]interface{}, exclude Recipient) ([]Recipient, error) {
	recipients := []Recipient{}
	if data["recipients"] != nil {
		trecipients := data["recipients"].([]interface{})
		for _, v := range trecipients {
			recipient := &Recipient{}
			tempJson, _ := json.Marshal(v)
			err := json.Unmarshal(tempJson, recipient)
			if err != nil {
				panic("unrecoverable conversion error - 1")
			}

			if exclude.Id != recipient.Id {
				recipients = append(recipients, *recipient)
			}
		}
	}
	return recipients, nil
}

func GetOriginsFromDocument(data map[string]interface{}, exclude Origin) ([]Origin, error) {
	origins := []Origin{}
	if data["origins"] != nil {
		torigins := data["origins"].([]interface{})
		for _, v := range torigins {
			origin := &Origin{}
			tempJson, _ := json.Marshal(v)
			err := json.Unmarshal(tempJson, origin)
			if err != nil {
				panic("unrecoverable conversion error - 1")
			}

			if exclude.Id != origin.Id {
				origins = append(origins, *origin)
			}
		}
	}
	return origins, nil
}

func GetTagsFromDocument(data map[string]interface{}, exclude Tag) ([]Tag, error) {
	mytags := []Tag{}
	if data["tags"] != nil {
		mytags2 := data["tags"].([]interface{})
		for _, v := range mytags2 {
			tag := &Tag{}
			tempTagJson, _ := json.Marshal(v)
			err := json.Unmarshal(tempTagJson, tag)
			if err != nil {
				panic("unrecoverable conversion error - 1")
			}

			if exclude.Id != tag.Id {
				mytags = append(mytags, *tag)
			}
		}
	}
	return mytags, nil
}

/**
* attaches author to source document
**/
func AttachAuthor(sourceName, sourceId, targetName, targetId string, sourceContent, targetContent map[string]interface{}) {
	doc := map[string]interface{}{
		"authorId": targetContent["_id"],
	}
	Upsert("koding", sourceName, sourceId, doc)
}

/**
* attaches author to source document
**/
func AttachGroup(sourceName, sourceId, targetName, targetId string, sourceContent, targetContent map[string]interface{}) {
	doc := map[string]interface{}{
		"groupId": targetContent["_id"],
	}
	Upsert("koding", sourceName, sourceId, doc)
}

/**
* attaches recipients to source document
**/
func AttachOrigin(sourceName, sourceId, targetName, targetId string, sourceContent, targetContent map[string]interface{}) {
	m, _ := Get("koding", sourceName, sourceId)

	origins, _ := GetOriginsFromDocument(m, Origin{Id: targetId})
	t := Origin{
		Id:   targetId,
		Name: targetContent["name"].(string),
	}

	origins = append(origins, t)
	doc := map[string]interface{}{
		"origins": origins,
	}

	Upsert("koding", sourceName, sourceId, doc)
}

/**
* attaches recipients to source document
**/
func AttachReceipent(sourceName, sourceId, targetName, targetId string, sourceContent, targetContent map[string]interface{}) {
	m, _ := Get("koding", sourceName, sourceId)

	recipients, _ := GetRecipientsFromDocument(m, Recipient{Id: targetId})
	t := Recipient{
		Id:   targetId,
		Slug: targetContent["slug"].(string),
		Name: targetContent["name"].(string),
	}

	recipients = append(recipients, t)
	doc := map[string]interface{}{
		"recipients": recipients,
	}

	Upsert("koding", sourceName, sourceId, doc)
}

/**
* attaches tag to source document
 */
func AttachTag(sourceName, sourceId, targetName, targetId string, sourceContent, targetContent map[string]interface{}) {
	m, _ := Get("koding", sourceName, sourceId)

	mytags, _ := GetTagsFromDocument(m, Tag{Id: targetId})
	t := Tag{
		Id:    targetId,
		Group: targetContent["group"].(string),
		Slug:  targetContent["slug"].(string),
		Name:  targetContent["name"].(string),
		Title: targetContent["title"].(string),
	}

	mytags = append(mytags, t)
	doc := map[string]interface{}{
		"tags": mytags,
	}

	Upsert("koding", sourceName, sourceId, doc)
}

/** actions for rabbitmq **/

func (controller *Controller) ActionUpdateNode(data map[string]interface{}) bool {

	if _, ok := data["bongo_"]; !ok {
		return true
	}

	if _, ok := data["data"]; !ok {
		return true
	}

	bongo := data["bongo_"].(map[string]interface{})
	obj := data["data"].(map[string]interface{})

	sourceId := fmt.Sprintf("%s", obj["_id"])
	sourceName := fmt.Sprintf("%s", bongo["constructorName"])

	if !CheckIfEligible(sourceName, "") {
		return true
	}

	sourceContent, err := mongohelper.Fetch(sourceId, sourceName)
	if err != nil {
		return true
	}

	Upsert("koding", sourceName, sourceId, sourceContent)
	return true
}

func (controller *Controller) ActionDeleteRelationship(data map[string]interface{}) bool {
	if data["as"].(string) == "tag" {

		sourceId := data["sourceId"].(string)
		sourceName := data["sourceName"].(string)
		targetId := data["targetId"].(string)

		m, _ := Get("koding", sourceName, sourceId)
		mytags, _ := GetTagsFromDocument(m, Tag{Id: targetId})

		doc := map[string]interface{}{
			"tags": mytags,
		}

		Upsert("koding", sourceName, sourceId, doc)
	}
	return true
}

func (controller *Controller) ActionDeleteNode(data map[string]interface{}) bool {
	if _, ok := data["_id"]; !ok {
		return true
	}

	if _, ok := data["bongo_"]; !ok {
		return true
	}

	sourceId := data["_id"].(string)

	c := data["bongo_"].(map[string]interface{})
	constructorName := c["constructorName"]
	DeleteNode(sourceId, constructorName.(string))
	return true
}

func (controller *Controller) ActionCreateNode(data map[string]interface{}) bool {

	sourceId, sourceName := data["sourceId"].(string), data["sourceName"].(string)
	targetId, targetName := data["targetId"].(string), data["targetName"].(string)

	/** begin guarding... **/
	if !CheckIfEligible(sourceName, targetName) {
		return true
	}

	sourceContent, err := mongohelper.Fetch(sourceId, sourceName)
	if err != nil {
		return true
	}

	targetContent, err := mongohelper.Fetch(targetId, targetName)
	if err != nil {
		return true
	}

	/** end guard **/

	IndexNode(sourceId, sourceName, sourceContent)
	IndexNode(targetId, targetName, targetContent)

	if _, ok := data["as"]; !ok {
		return true
	}

	if _, ok := data["_id"]; !ok {
		return true
	}

	// we dont know if a relation creates an array,
	// or creates a reference. so we code them all..
	fn, ok := Attachers[data["as"].(string)]
	if ok {
		fn(sourceName, sourceId, targetName, targetId, sourceContent, targetContent)
	}

	return true
}
