package validate

import (
	"io/ioutil"
	"launchpad.net/goyaml"
	"testing"
)

func TestUrlIsValid(t *testing.T) {
	contents, err := ioutil.ReadFile(validateYmlPath)
	if err != nil {
		t.Errorf("Error reading validate.yml: %v", err)
		t.FailNow()
	}

	var testData map[interface{}]interface{}
	err = goyaml.Unmarshal(contents, &testData)

	tests, ok := testData["tests"]
	if !ok {
		t.Errorf("Conformance file was not in expected format.")
		t.FailNow()
	}

	urlTests, ok := tests.(map[interface{}]interface{})["urls"]
	if !ok {
		t.Errorf("Conformance file did not contain urls tests")
		t.FailNow()
	}

	for _, testCase := range urlTests.([]interface{}) {
		test := testCase.(map[interface{}]interface{})
		text, _ := test["text"]
		description, _ := test["description"]
		expected, _ := test["expected"]

		actual := UrlIsValid(text.(string), true, true)
		if actual != expected {
			t.Errorf("UrlIsValid returned incorrect value for test [%s]. Expected:%v Got:%v", description, expected, actual)
		}
	}
}

func TestUrlWithoutProtocol(t *testing.T) {
	contents, err := ioutil.ReadFile(validateYmlPath)
	if err != nil {
		t.Errorf("Error reading validate.yml: %v", err)
		t.FailNow()
	}

	var testData map[interface{}]interface{}
	err = goyaml.Unmarshal(contents, &testData)

	tests, ok := testData["tests"]
	if !ok {
		t.Errorf("Conformance file was not in expected format.")
		t.FailNow()
	}

	urlTests, ok := tests.(map[interface{}]interface{})["urls_without_protocol"]
	if !ok {
		t.Errorf("Conformance file did not contain urls_without_protocol tests")
		t.FailNow()
	}

	for _, testCase := range urlTests.([]interface{}) {
		test := testCase.(map[interface{}]interface{})
		text, _ := test["text"]
		description, _ := test["description"]
		expected, _ := test["expected"]

		actual := UrlIsValid(text.(string), false, true)
		if actual != expected {
			t.Errorf("UrlIsValid returned incorrect value for test [%s]. Expected:%v Got:%v", description, expected, actual)
		}
	}
}
