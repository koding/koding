package validate

import (
	"io/ioutil"
	"testing"

	"launchpad.net/goyaml"
)

func TestUsernameIsValid(t *testing.T) {
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

	usernameTests, ok := tests.(map[interface{}]interface{})["usernames"]
	if !ok {
		t.Errorf("Conformance file did not contain username tests")
		t.FailNow()
	}

	for _, testCase := range usernameTests.([]interface{}) {
		test := testCase.(map[interface{}]interface{})
		text, _ := test["text"]
		description, _ := test["description"]
		expected, _ := test["expected"]

		actual := UsernameIsValid(text.(string))
		if actual != expected {
			t.Errorf("UsernameIsValid returned incorrect value for test [%s]. Expected:%v Got:%v", description, expected, actual)
		}
	}
}
