package smtpapi

import (
	"encoding/json"
	"io/ioutil"
	"reflect"
	"testing"
)

func ExampleJson() map[string]interface{} {
	data, _ := ioutil.ReadFile("smtpapi_test_strings.json")
	var f interface{}
	json.Unmarshal(data, &f)
	json := f.(map[string]interface{})
	return json
}

func TestNewSMTPIAPIHeader(t *testing.T) {
	header := NewSMTPAPIHeader()
	if header == nil {
		t.Error("NewSMTPAPIHeader() should never return nil")
	}
}

func TestAddTo(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddTo("addTo@mailinator.com")
	result, _ := header.JSONString()
	if result != ExampleJson()["add_to"] {
		t.Errorf("Result did not match")
	}
}

func TestAddTos(t *testing.T) {
	header := NewSMTPAPIHeader()
	tos := []string{"addTo@mailinator.com"}
	header.AddTos(tos)
	result, _ := header.JSONString()
	if result != ExampleJson()["add_to"] {
		t.Errorf("Result did not match")
	}
}

func TestSetTos(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.SetTos([]string{"setTos@mailinator.com"})
	result, _ := header.JSONString()
	if result != ExampleJson()["set_tos"] {
		t.Errorf("Result did not match")
	}
}

func TestAddSubstitution(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddSubstitution("sub", "val")
	result, _ := header.JSONString()
	if result != ExampleJson()["add_substitution"] {
		t.Errorf("Result did not match")
	}
}

func TestAddSubstitutions(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddSubstitutions("sub", []string{"val"})
	result, _ := header.JSONString()
	if result != ExampleJson()["add_substitution"] {
		t.Errorf("Result did not match")
	}
}

func TestSetSubstitutions(t *testing.T) {
	header := NewSMTPAPIHeader()
	sub := make(map[string][]string)
	sub["sub"] = []string{"val"}
	header.SetSubstitutions(sub)
	result, _ := header.JSONString()
	if result != ExampleJson()["set_substitutions"] {
		t.Errorf("Result did not match")
	}
}

func TestAddSection(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddSection("set_section_key", "set_section_value")
	header.AddSection("set_section_key_2", "set_section_value_2")
	result, _ := header.JSONString()
	if result != ExampleJson()["add_section"] {
		t.Errorf("Result did not match")
	}
}

func TestSetSections(t *testing.T) {
	header := NewSMTPAPIHeader()
	sections := make(map[string]string)
	sections["set_section_key"] = "set_section_value"
	header.SetSections(sections)
	result, _ := header.JSONString()
	if result != ExampleJson()["set_sections"] {
		t.Errorf("Result did not match")
	}
}

func TestAddCategory(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddCategory("addCategory")
	header.AddCategory("addCategory2")
	result, _ := header.JSONString()
	if result != ExampleJson()["add_category"] {
		t.Errorf("Result did not match")
	}
}

func TestAddCategoryUnicode(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddCategory("カテゴリUnicode")
	header.AddCategory("カテゴリ2Unicode")
	result, _ := header.JSONString()
	if result != ExampleJson()["add_category_unicode"] {
		t.Errorf("Result did not match")
	}
}

func TestAddCategories(t *testing.T) {
	header := NewSMTPAPIHeader()
	categories := []string{"addCategory", "addCategory2"}
	header.AddCategories(categories)
	result, _ := header.JSONString()
	if result != ExampleJson()["add_category"] {
		t.Errorf("Result did not match")
	}
}

func TestSetCategories(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.SetCategories([]string{"setCategories"})
	result, _ := header.JSONString()
	if result != ExampleJson()["set_categories"] {
		t.Errorf("Result did not match")
	}
}

func TestAddUniqueArg(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddUniqueArg("add_unique_argument_key", "add_unique_argument_value")
	header.AddUniqueArg("add_unique_argument_key_2", "add_unique_argument_value_2")
	result, _ := header.JSONString()
	if result != ExampleJson()["add_unique_arg"] {
		t.Errorf("Result did not match")
	}
}

func TestSetUniqueArgs(t *testing.T) {
	header := NewSMTPAPIHeader()
	args := make(map[string]string)
	args["set_unique_argument_key"] = "set_unique_argument_value"
	header.SetUniqueArgs(args)
	result, _ := header.JSONString()
	if result != ExampleJson()["set_unique_args"] {
		t.Errorf("Result did not match")
	}
}

func TestAddFilter(t *testing.T) {
	header := NewSMTPAPIHeader()
	header.AddFilter("footer", "text/html", "<strong>boo</strong>")
	if len(header.Filters) != 1 {
		t.Error("AddFilter failed")
	}
}

func TestSetFilter(t *testing.T) {
	header := NewSMTPAPIHeader()
	filter := &Filter{
		Settings: make(map[string]string),
	}
	filter.Settings["enable"] = "1"
	filter.Settings["text/plain"] = "You can haz footers!"
	header.SetFilter("footer", filter)
	result, _ := header.JSONString()
	if result != ExampleJson()["set_filters"] {
		t.Errorf("Result did not match")
	}
}

func TestJSONString(t *testing.T) {
	header := NewSMTPAPIHeader()
	result, _ := header.JSONString()
	if result != ExampleJson()["json_string"] {
		t.Errorf("Result did not match")
	}
}

func TestJSONStringWithAdds(t *testing.T) {
	validHeader, _ := json.Marshal([]byte(`{"to":["test@email.com"],"sub":{"subKey":["subValue"]},"section":{"testSection":"sectionValue"},"category":["testCategory"],"unique_args":{"testUnique":"uniqueValue"},"filters":{"testFilter":{"settings":{"filter":"filterValue"}}}}`))
	header := NewSMTPAPIHeader()
	header.AddTo("test@email.com")
	header.AddSubstitution("subKey", "subValue")
	header.AddSection("testSection", "sectionValue")
	header.AddCategory("testCategory")
	header.AddUniqueArg("testUnique", "uniqueValue")
	header.AddFilter("testFilter", "filter", "filterValue")
	if h, e := header.JSONString(); e != nil {
		t.Errorf("Error! %s", e)
	} else {
		testHeader, _ := json.Marshal([]byte(h))
		if reflect.DeepEqual(testHeader, validHeader) {
			t.Logf("Success")
		} else {
			t.Errorf("Invalid header")
		}
	}
}

func TestJSONStringWithSets(t *testing.T) {
	validHeader, _ := json.Marshal([]byte(`{"to":["test@email.com"],"sub":{"subKey":["subValue"]},"section":{"testSection":"sectionValue"},"category":["testCategory"],"unique_args":{"testUnique":"uniqueValue"},"filters":{"testFilter":{"settings":{"filter":"filterValue"}}}}`))
	header := NewSMTPAPIHeader()
	header.SetTos([]string{"test@email.com"})
	sub := make(map[string][]string)
	sub["subKey"] = []string{"subValue"}
	header.SetSubstitutions(sub)
	sections := make(map[string]string)
	sections["testSection"] = "sectionValue"
	header.SetSections(sections)
	header.SetCategories([]string{"testCategory"})
	unique := make(map[string]string)
	unique["testUnique"] = "uniqueValue"
	header.SetUniqueArgs(unique)
	header.AddFilter("testFilter", "filter", "filterValue")
	if h, e := header.JSONString(); e != nil {
		t.Errorf("Error! %s", e)
	} else {
		testHeader, _ := json.Marshal([]byte(h))
		if reflect.DeepEqual(testHeader, validHeader) {
			t.Logf("Success")
		} else {
			t.Errorf("Invalid header")
		}
	}
}
