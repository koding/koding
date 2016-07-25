package extract

import (
	"fmt"
	"io/ioutil"
	"testing"

	"launchpad.net/goyaml"
)

func TestExtractHashtags(t *testing.T) {
	contents, err := ioutil.ReadFile(extractYmlPath)
	if err != nil {
		t.Errorf("Error reading extract.yml: %v", err)
		t.FailNow()
	}

	var conformance = &Conformance{}
	err = goyaml.Unmarshal(contents, &conformance)
	if err != nil {
		t.Errorf("Error parsing extract.yml: %v", err)
		t.FailNow()
	}

	hashtagTests, ok := conformance.Tests["hashtags"]
	if !ok {
		t.Errorf("Conformance file did not contain 'hashtags' key")
		t.FailNow()
	}

	for _, test := range hashtagTests {
		result := ExtractHashtags(test.Text)

		expected, ok := test.Expected.([]interface{})
		if !ok {
			fmt.Printf("e: %#v\n", test)
			t.Errorf("Expected value in conformance file was not a list. Test name: %s.\n", test.Description)
			t.FailNow()
		}

		if len(result) != len(expected) {
			t.Errorf("Wrong number of entities returned for text [%s]. Expected:%v Got:%v.\n", test.Text, expected, result)
			continue
		}

		for n, e := range expected {
			actual := result[n]
			if actual.hashtag != e {
				t.Errorf("ExtractHashtags returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, e, actual.Hashtag)
			}

			if actual.Type != HASH_TAG {
				t.Errorf("ExtractHashtags returned entity with wrong type. Expected:HASH_TAG Got:%v", actual.Type)
			}
		}
	}
}

func TestExtractHashtagsWithIndices(t *testing.T) {
	contents, err := ioutil.ReadFile(extractYmlPath)
	if err != nil {
		t.Errorf("Error reading extract.yml: %v", err)
		t.FailNow()
	}

	var conformance = &Conformance{}
	err = goyaml.Unmarshal(contents, &conformance)
	if err != nil {
		t.Errorf("Error parsing extract.yml: %v", err)
		t.FailNow()
	}

	hashtagTests, ok := conformance.Tests["hashtags_with_indices"]
	if !ok {
		t.Errorf("Conformance file did not contain 'hashtags_with_indices' key")
		t.FailNow()
	}

	for _, test := range hashtagTests {
		result := ExtractHashtags(test.Text)

		expected, ok := test.Expected.([]interface{})
		if !ok {
			fmt.Printf("e: %#v\n", test)
			t.Errorf("Expected value in conformance file was not a list. Test name: %s.\n", test.Description)
			t.FailNow()
		}

		if len(result) != len(expected) {
			t.Errorf("Wrong number of entities returned for text [%s]. Expected:%v Got:%v.\n", test.Text, expected, result)
			continue
		}

		for n, e := range expected {
			actual := result[n]
			expectedMap, ok := e.(map[interface{}]interface{})
			if !ok {
				t.Errorf("Expected value was not a map. Test name: %s\n", test.Description)
				continue
			}

			hashtag, ok := expectedMap["hashtag"]
			if !ok {
				t.Errorf("Expected value did not contain hashtag. Test name: %s\n", test.Description)
				continue
			}

			if actual.hashtag != hashtag {
				t.Errorf("ExtractHashtags returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, hashtag, actual.Hashtag)
			}

			indices, ok := expectedMap["indices"]
			if !ok {
				t.Errorf("Expected value did not contain indices. Test name: %s\n", test.Description)
				continue
			}

			indicesList := indices.([]interface{})
			if len(indicesList) != 2 {
				t.Errorf("Indices did not contain 2 values. Test name: %s\n", test.Description)
				continue
			}

			if indicesList[0] != actual.Range.Start || indicesList[1] != actual.Range.Stop {
				t.Errorf("ExtractMentionedScreenNames did not return correct indices [%s]. Expected:(%d, %d) Got:%s)",
					test.Text, indicesList[0], indicesList[1], actual.Range)
			}
		}
	}
}
