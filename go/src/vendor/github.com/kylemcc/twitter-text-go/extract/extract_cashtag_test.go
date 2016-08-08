package extract

import (
	"fmt"
	"io/ioutil"
	"testing"

	"launchpad.net/goyaml"
)

func TestExtractCashtags(t *testing.T) {
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

	cashtagTests, ok := conformance.Tests["cashtags"]
	if !ok {
		t.Errorf("Conformance file did not contain 'cashtags' key")
		t.FailNow()
	}

	for _, test := range cashtagTests {
		result := ExtractCashtags(test.Text)

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
			if actual.cashtag != e {
				t.Errorf("ExtractCashtags returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, e, actual.Cashtag)
			}

			if actual.Type != CASH_TAG {
				t.Errorf("ExtractCashtags returned entity with wrong type. Expected:CASH_TAG Got:%v", actual.Type)
			}
		}
	}
}

func TestExtractCashtagsWithIndices(t *testing.T) {
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

	cashtagTests, ok := conformance.Tests["cashtags_with_indices"]
	if !ok {
		t.Errorf("Conformance file did not contain 'cashtags_with_indices' key")
		t.FailNow()
	}

	for _, test := range cashtagTests {
		result := ExtractCashtags(test.Text)

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

			cashtag, ok := expectedMap["cashtag"]
			if !ok {
				t.Errorf("Expected value did not contain cashtag. Test name: %s\n", test.Description)
				continue
			}

			if actual.cashtag != cashtag {
				t.Errorf("ExtractCashtags returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, cashtag, actual.Cashtag)
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
