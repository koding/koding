package kloud

import (
	"fmt"
	"koding/db/models"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"
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

func TestTerraformTemplate_InjectKodingData(t *testing.T) {
	template, err := newTerraformTemplate(testTemplate)
	if err != nil {
		t.Fatal(err)
	}

	data := &kodingData{
		Account: &models.Account{
			Profile: models.AccountProfile{
				Nickname:  "fatih",
				FirstName: "Fatih",
				LastName:  "Arslan",
				Hash:      "124",
			},
		},
		Group: &models.Group{
			Title: "MyGroup",
			Slug:  "my_group",
		},
		User: &models.User{
			Name:  "Fatih",
			Email: "fatih@koding.com",
		},
	}

	if err := template.injectKodingVariables(data); err != nil {
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
	template, err := newTerraformTemplate(testTemplate)
	if err != nil {
		t.Fatal(err)
	}

	prefix := "custom"
	data := map[string]string{
		"foo": "1",
		"bar": "example@example.com",
		"qaz": "hello",
	}

	if err := template.injectCustomVariables(prefix, data); err != nil {
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
	}

	if err := template.DecodeVariable(&variable); err != nil {
		t.Fatal(err)
	}

	equals(t, "example@example.com", variable.CustomBar.Default)
	equals(t, "1", variable.CustomFoo.Default)
	equals(t, "hello", variable.CustomQaz.Default)
	equals(t, "fatih", variable.Username.Default)
}

func TestTerraformTemplate_DecodeProvider(t *testing.T) {
	template, err := newTerraformTemplate(testTemplate)
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
	template, err := newTerraformTemplate(userTestTemplate)
	if err != nil {
		t.Fatal(err)
	}

	vars, err := template.detectUserVariables()
	if err != nil {
		t.Fatal(err)
	}

	fmt.Printf("vars = %+v\n", vars)
}

// equals fails the test if exp is not equal to act.
func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.FailNow()
	}
}
