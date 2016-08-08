package validate

import (
	"io/ioutil"
	"testing"

	"launchpad.net/goyaml"
)

func TestHashtagIsValid(t *testing.T) {
	contents, err := ioutil.ReadFile(validateYmlPath)
	if err != nil {
		t.Errorf("Error reading validate.yml: %v", err)
		t.FailNow()
	}

	var testData map[interface{}]interface{}
	err = goyaml.Unmarshal(contents, &testData)
	if err != nil {
		t.Fatalf("error unmarshaling data: %v\n", err)
	}

	tests, ok := testData["tests"]
	if !ok {
		t.Errorf("Conformance file was not in expected format.")
		t.FailNow()
	}

	hashtagTests, ok := tests.(map[interface{}]interface{})["hashtags"]
	if !ok {
		t.Errorf("Conformance file did not contain hashtag tests")
		t.FailNow()
	}

	for _, testCase := range hashtagTests.([]interface{}) {
		test := testCase.(map[interface{}]interface{})
		text, _ := test["text"]
		description, _ := test["description"]
		expected, _ := test["expected"]

		actual := HashtagIsValid(text.(string))
		if actual != expected {
			t.Errorf("HashtagIsValid returned incorrect value for test [%s]. Expected:%v Got:%v", description, expected, actual)
		}
	}
}
