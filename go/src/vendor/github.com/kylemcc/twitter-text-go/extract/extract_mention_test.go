package extract

import (
	"fmt"
	"io/ioutil"
	"testing"

	"launchpad.net/goyaml"
)

func TestExtractMentions(t *testing.T) {
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

	mentionTests, ok := conformance.Tests["mentions"]
	if !ok {
		t.Errorf("Conformance file did not contain 'mentions' key")
		t.FailNow()
	}

	for _, test := range mentionTests {
		result := ExtractMentionedScreenNames(test.Text)

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
			if actual.screenName != e {
				t.Errorf("ExtractMentionedScreenNames returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, e, actual.Text)
			}

			if actual.Type != MENTION {
				t.Errorf("ExtractMentionedScreenNames returned entity with wrong type. Expected:MENTION Got:%v", actual.Type)
			}
		}
	}
}

func TestExtractMentionsWithIndices(t *testing.T) {
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

	mentionTests, ok := conformance.Tests["mentions_with_indices"]
	if !ok {
		t.Errorf("Conformance file did not contain 'mentions_with_indices' key")
		t.FailNow()
	}

	for _, test := range mentionTests {
		result := ExtractMentionedScreenNames(test.Text)

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

			mention, ok := expectedMap["screen_name"]
			if !ok {
				t.Errorf("Expected value did not contain screen_name. Test name: %s\n", test.Description)
				continue
			}

			if actual.screenName != mention {
				t.Errorf("ExtractMentionedScreenNames returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, mention, actual.ScreenName)
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

func TestExtractMentionsOrListsWithIndices(t *testing.T) {
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

	tests, ok := conformance.Tests["mentions_or_lists_with_indices"]
	if !ok {
		t.Errorf("Conformance file did not contain 'mentions_or_lists_with_indices' key")
		t.FailNow()
	}

	for _, test := range tests {
		result := ExtractMentionsOrLists(test.Text)

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

			mention, ok := expectedMap["screen_name"]
			if !ok {
				t.Errorf("Expected value did not contain screen_name. Test name: %s\n", test.Description)
				continue
			}

			listSlug, ok := expectedMap["list_slug"]
			if !ok {
				t.Errorf("Expected value did not contain list_slug. Test name: %s\n", test.Description)
				continue
			}

			if actual.screenName != mention {
				t.Errorf("ExtractMentionedScreenNames returned incorrect ScreenName value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, mention, actual.ScreenName)
			}

			if actual.listSlug != listSlug {
				t.Errorf("ExtractMentionedScreenNames returned incorrect ListSlug value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, listSlug, actual.ListSlug)
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

func TestExtractReplyScreenname(t *testing.T) {
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

	replyTests, ok := conformance.Tests["replies"]
	if !ok {
		t.Errorf("Conformance file did not contain 'replies' key")
		t.FailNow()
	}

	for _, test := range replyTests {
		result := ExtractReplyScreenname(test.Text)

		if result == nil {
			if test.Expected != nil {
				t.Errorf("ExtractReplyScreenname did not return the expected result for text [%s]: %v", test.Text, test.Expected)
			}
		} else {
			if result.screenName != test.Expected {
				t.Errorf("ExtractReplyScreenname returned incorrect value for test: [%s]. Expected:[%v] Got:[%v]\n", test.Text, test.Expected, result.Text)
			}

			if result.Type != MENTION {
				t.Errorf("ExtractReplyScreenname returned entity with wrong type. Expected:MENTION Got:%v", result.Type)
			}
		}
	}
}
