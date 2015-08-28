package kloud

import (
	"fmt"
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

// equals fails the test if exp is not equal to act.
func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.FailNow()
	}
}
