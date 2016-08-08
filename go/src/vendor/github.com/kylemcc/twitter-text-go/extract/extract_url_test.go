package extract

import (
	"fmt"
	"io/ioutil"
	"testing"

	"launchpad.net/goyaml"
)

func TestExtractUrls(t *testing.T) {
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

	urlTests, ok := conformance.Tests["urls"]
	if !ok {
		t.Errorf("Conformance file did not contain 'urls' key")
		t.FailNow()
	}

	for _, test := range urlTests {
		result := ExtractUrls(test.Text)

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
			tmpValue := e.(string)
			if actual.Text != tmpValue {
				t.Errorf("ExtractUrls returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, tmpValue, actual.Text)
			}

			if actual.Type != URL {
				t.Errorf("ExtractMentionedScreenNames returned entity with wrong type. Expected:MENTION Got:%v", actual.Type)
			}
		}
	}
}

func TestExtractUrlsWithIndices(t *testing.T) {
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

	urlTests, ok := conformance.Tests["urls_with_indices"]
	if !ok {
		t.Errorf("Conformance file did not contain 'urls_with_indices' key")
		t.FailNow()
	}

	for _, test := range urlTests {
		result := ExtractUrls(test.Text)

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

			url, ok := expectedMap["url"]
			if !ok {
				t.Errorf("Expected value did not contain url. Test name: %s\n", test.Description)
				continue
			}

			if actual.Text != url {
				t.Errorf("ExtractUrls returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, url, actual.Text)
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
				t.Errorf("ExtractUrls did not return correct indices [%s]. Expected:(%d, %d) Got:%s)",
					test.Text, indicesList[0], indicesList[1], actual.Range)
			}

			if actual.Type != URL {
				t.Errorf("ExtractUrls returned entity with wrong type. Expected:URL Got:%v", actual.Type)
			}
		}
	}
}

func TestTlds(t *testing.T) {
	contents, err := ioutil.ReadFile(tldYmlPath)
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

	urlTests, ok := conformance.Tests["country"]
	if !ok {
		t.Errorf("Conformance file did not contain 'country' key")
		t.FailNow()
	}

	if generic, ok := conformance.Tests["generic"]; !ok {
		t.Errorf("Conformance file did not contain 'generic' key")
		t.FailNow()
	} else {
		urlTests = append(urlTests, generic...)
	}

	for _, test := range urlTests {
		result := ExtractUrls(test.Text)

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
			tmpValue := e.(string)
			if actual.Text != tmpValue {
				t.Errorf("ExtractUrls returned incorrect value for test: [%s]. Expected:[%s] Got:[%s]\n", test.Text, tmpValue, actual.Text)
			}

			if actual.Type != URL {
				t.Errorf("ExtractMentionedScreenNames returned entity with wrong type. Expected:MENTION Got:%v", actual.Type)
			}
		}
	}
}
