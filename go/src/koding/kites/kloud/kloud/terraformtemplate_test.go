package kloud

import (
	"fmt"
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

func TestTerraformTemplate(t *testing.T) {
	template, err := newTerraformTemplate(testTemplate)
	if err != nil {
		t.Fatal(err)
	}

	out, err := template.jsonOutput()
	if err != nil {
		t.Fatal(err)
	}

	fmt.Println(out)
}
