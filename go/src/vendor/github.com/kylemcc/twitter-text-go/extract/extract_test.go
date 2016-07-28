package extract

import (
	"fmt"
	"os"
	"path"
)

type Conformance struct {
	Tests map[string][]*Test
}

type Test struct {
	Description string
	Text        string
	Expected    interface{}
}

var cwd, _ = os.Getwd()
var parentDir = path.Dir(cwd)
var extractYmlPath = path.Join(parentDir, "conformance", "extract.yml")
var tldYmlPath = path.Join(parentDir, "conformance", "tlds.yml")

func ExampleExtractEntities() {
	text := "tweet mentioning @username with a url http://t.co/abcde and a #hashtag"
	entities := ExtractEntities(text)

	for _, e := range entities {
		fmt.Printf("Entity:%s Type:%v\n", e.Text, e.Type)
	}
	// Output:
	// Entity:@username Type:MENTION
	// Entity:http://t.co/abcde Type:URL
	// Entity:#hashtag Type:HASH_TAG
}

func ExampleExtractMentionedScreenNames() {
	text := "mention @user1 @user2 and @user3"
	entities := ExtractMentionedScreenNames(text)
	for i, e := range entities {
		sn, _ := e.ScreenName()
		fmt.Printf("Match[%d]:%s Screenname:%s Range:%s\n", i, e.Text, sn, e.Range)
	}

	// Output:
	// Match[0]:@user1 Screenname:user1 Range:(8, 14)
	// Match[1]:@user2 Screenname:user2 Range:(15, 21)
	// Match[2]:@user3 Screenname:user3 Range:(26, 32)
}
