package provider_test

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"

	"github.com/koding/logging"

	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/stack/provider"
)

const testTemplate = `{
    "variable": {
        "username": {
            "default": "fatih"
        }
    },
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}",
            "region": "${var.aws_region}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
                "count": 2,
                "instance_type": "t2.micro",
                "user_data": "sudo apt-get install sl -y\ntouch /tmp/${var.username}.txt"
            }
        }
    }
}`

var log = logging.NewCustom("test", true)

func TestTerraformTemplate_NewNil(t *testing.T) {
	template, err := provider.ParseTemplate(testTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	if template.Variable == nil {
		t.Error("Variable field should be not nil")
	}

	if template.Output == nil {
		t.Error("Output field should be not nil")
	}

	if template.Provider == nil {
		t.Error("Provider field should be not nil")
	}

	if template.Resource == nil {
		t.Error("Resource field should be not nil")
	}
}

func TestTerraformTemplate_InjectKodingData(t *testing.T) {
	template, err := provider.ParseTemplate(testTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	data := &provider.KodingMeta{
		Username:  "Fatih",
		Email:     "fatih@koding.com",
		Nickname:  "fatih",
		Firstname: "Fatih",
		Lastname:  "Arslan",
		Hash:      "124",
		Title:     "MyGroup",
		Slug:      "my_group",
	}

	if err := template.InjectVariables("koding", data); err != nil {
		t.Fatal(err)
	}

	var variable struct {
		KodingAccountProfileFirstName struct {
			Default string
		} `hcl:"koding_account_profile_firstName"`
		KodingAccountProfileHash struct {
			Default string
		} `hcl:"koding_account_profile_hash"`
		KodingAccountProfileLastName struct {
			Default string
		} `hcl:"koding_account_profile_lastName"`
		KodingAccountProfileNickname struct {
			Default string
		} `hcl:"koding_account_profile_nickname"`
		KodingGroupSlug struct {
			Default string
		} `hcl:"koding_group_slug"`
		KodingGroupTitle struct {
			Default string
		} `hcl:"koding_group_title"`
		KodingUserEmail struct {
			Default string
		} `hcl:"koding_user_email"`
		KodingUserUsername struct {
			Default string
		} `hcl:"koding_user_username"`
	}

	if err := template.DecodeVariable(&variable); err != nil {
		t.Fatal(err)
	}

	equals(t, "Fatih", variable.KodingAccountProfileFirstName.Default)
	equals(t, "124", variable.KodingAccountProfileHash.Default)
	equals(t, "Arslan", variable.KodingAccountProfileLastName.Default)
	equals(t, "fatih", variable.KodingAccountProfileNickname.Default)
	equals(t, "my_group", variable.KodingGroupSlug.Default)
	equals(t, "MyGroup", variable.KodingGroupTitle.Default)
	equals(t, "Fatih", variable.KodingUserUsername.Default)
	equals(t, "fatih@koding.com", variable.KodingUserEmail.Default)
}

func TestTerraformTemplate_InjectCustomVariable(t *testing.T) {
	template, err := provider.ParseTemplate(testTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	prefix := "custom"
	data := provider.CustomMeta{
		"foo":           "1",
		"bar":           "example@example.com",
		"qaz":           "hello",
		"_notHidden":    "notHidden",
		"__hidden":      "${var.value}",
		"__rawContent":  "${var.custom___otherHidden}",
		"__otherHidden": "${var.value}",
	}

	if err := template.InjectVariables(prefix, data); err != nil {
		t.Fatal(err)
	}

	var variable struct {
		CustomBar struct {
			Default string
		} `hcl:"custom_bar"`
		CustomFoo struct {
			Default string
		} `hcl:"custom_foo"`
		CustomQaz struct {
			Default string
		} `hcl:"custom_qaz"`
		Username struct {
			Default string
		} `hcl:"username"`
		NotHidden struct {
			Default string
		} `hcl:"custom__notHidden"`
		Hidden struct {
			Default string
		} `hcl:"custom___hidden"`
		RawContent struct {
			Default string
		} `hcl:"custom___rawContent"`
		OtherHidden struct {
			Default string
		} `hcl:"custom___otherHidden"`
	}

	if err := template.DecodeVariable(&variable); err != nil {
		t.Fatal(err)
	}

	equals(t, "example@example.com", variable.CustomBar.Default)
	equals(t, "1", variable.CustomFoo.Default)
	equals(t, "hello", variable.CustomQaz.Default)
	equals(t, "fatih", variable.Username.Default)
	equals(t, "notHidden", variable.NotHidden.Default)
	equals(t, "", variable.Hidden.Default)
	equals(t, "", variable.RawContent.Default)
	equals(t, "", variable.OtherHidden.Default)
}

func TestTerraformTemplate_DecodeProvider(t *testing.T) {
	template, err := provider.ParseTemplate(testTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	var provider struct {
		Aws struct {
			Region    string
			AccessKey string `hcl:"access_key"`
			SecretKey string `hcl:"secret_key"`
		}
	}

	if err := template.DecodeProvider(&provider); err != nil {
		t.Fatal(err)
	}

	equals(t, "${var.aws_access_key}", provider.Aws.AccessKey)
	equals(t, "${var.aws_secret_key}", provider.Aws.SecretKey)
	equals(t, "${var.aws_region}", provider.Aws.Region)
}

func TestTerraformTemplate_ShadowVariables(t *testing.T) {
	userTestTemplate := `{
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}",
            "region": "${var.aws_region}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
				"bar": "${var.aws_access_key}",
                "instance_type": "t2.micro",
                "user_data": "echo ${var.aws_secret_key} ${base64encode(var.aws_secret_key)} >> /tmp/keys.txt"
            }
        }
    }
}`
	template, err := provider.ParseTemplate(userTestTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	err = template.ShadowVariables("FORBIDDEN", "aws_access_key", "aws_secret_key")
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println(template)
}

func TestTerraformTemplate_DetectUserVariables(t *testing.T) {
	userTestTemplate := `{
    "variable": {
        "username": {
            "default": "fatih"
        }
    },
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}",
            "region": "${var.aws_region}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
                "count": "${var.userInput_count}",
                "instance_type": "t2.micro",
                "user_data": "sudo apt-get install ${var.userInput_foo} -y\ntouch /tmp/${var.username}.txt"
            }
        }
    }
}`
	template, err := provider.ParseTemplate(userTestTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	vars, err := template.DetectUserVariables("")
	if err != nil {
		t.Fatal(err)
	}

	has := func(v string) bool {
		mustHave := []string{
			"aws_access_key",
			"aws_secret_key",
			"aws_region",
			"userInput_foo",
			"userInput_count",
			"username",
		}

		for _, m := range mustHave {
			if m == v {
				return true
			}
		}

		return false
	}

	for key := range vars {
		if !has(key) {
			t.Errorf("Variable '%s' should exist in the template", key)
		}
	}
}

func TestTerraformTemplate_FillVariables(t *testing.T) {
	userTestTemplate := `{
    "variable": {
        "username": {
            "default": "fatih"
        }
    },
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}",
            "region": "${var.aws_region}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
                "count": "${var.userInput_count}",
                "instance_type": "t2.micro",
                "user_data": "sudo apt-get install ${var.userInput_foo} -y\ntouch /tmp/${var.username}.txt"
            }
        }
    }
}`
	template, err := provider.ParseTemplate(userTestTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	if err := template.FillVariables("userInput"); err != nil {
		t.Fatal(err)
	}

	var variable struct {
		UserInputCount struct {
			Default string
		} `hcl:"userInput_count"`
		UserInputFoo struct {
			Default string
		} `hcl:"userInput_foo"`
	}

	if err := template.DecodeVariable(&variable); err != nil {
		t.Fatal(err)
	}

	// these should be empty
	equals(t, "", variable.UserInputCount.Default)
	equals(t, "", variable.UserInputFoo.Default)
}

func TestTerraformTemplate_SetAWSRegion(t *testing.T) {
	missingRegionTemplate := `{
    "variable": {
        "username": {
            "default": "fatih"
        }
    },
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
                "count": "${var.userInput_count}",
                "instance_type": "t2.micro",
                "user_data": "sudo apt-get install ${var.userInput_foo} -y\ntouch /tmp/${var.username}.txt"
            }
        }
    }
}`

	template, err := provider.ParseTemplate(missingRegionTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	// TODO(rjeczalik): move the test to provider/aws
	s := &aws.Stack{BaseStack: &provider.BaseStack{Builder: &provider.Builder{Template: template}}}
	if err := s.SetAwsRegion("us-east-1"); err != nil {
		t.Fatal(err)
	}

	var provider struct {
		Aws struct {
			Region    string `hcl:"region"`
			AccessKey string `hcl:"access_key"`
			SecretKey string `hcl:"secret_key"`
		}
	}

	if err := template.DecodeProvider(&provider); err != nil {
		t.Fatal(err)
	}

	equals(t, "${var.aws_access_key}", provider.Aws.AccessKey)
	equals(t, "${var.aws_secret_key}", provider.Aws.SecretKey)
	equals(t, "us-east-1", provider.Aws.Region)
}

func TestTerraformTemplate_Encoding(t *testing.T) {
	userTestTemplate := `{
	    "variable": {
	        "username": {
	            "default": "fatih"
	        }
	    },
	    "provider": {
	        "aws": {
	            "access_key": "${var.aws_access_key}",
	            "secret_key": "${var.aws_secret_key}",
	            "region": "${var.aws_region}"
	        }
	    },
	    "resource": {
	        "aws_instance": {
	            "example": {
	                "instance_type": "t2.micro",
	                "user_data": "echo 'fatih' > /tmp/hello.txt\necho 'arslan' > /tmp/${var.username}.txt"
	            }
	        }
	    }
	}`

	template, err := provider.ParseTemplate(userTestTemplate, log)
	if err != nil {
		t.Fatal(err)
	}

	var resource struct {
		AwsInstance struct {
			Example struct {
				UserData string `hcl:"user_data"`
			} `hcl:"example"`
		} `hcl:"aws_instance"`
	}

	if err := template.DecodeResource(&resource); err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(resource.AwsInstance.Example.UserData, `>`) {
		t.Errorf("Brackets should be encoded\n\tOutput: %s\n", resource.AwsInstance.Example.UserData)
	}
}

// equals fails the test if exp is not equal to act.
func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.FailNow()
	}
}
