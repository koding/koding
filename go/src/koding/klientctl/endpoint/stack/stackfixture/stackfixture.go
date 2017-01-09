package stackfixture

var StackHCL = []byte(`provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
}

resource "aws_instance" "example-instance" {
	instance_type = "t2.nano"
	ami = ""
	tags {
		Name = "${var.koding_user_username}-${var.koding_group_slug}"
	}
	user_data = "echo \"hello world!\" >> /helloworld.txt"
}`)

var StackJSON = []byte(`{
	"provider": {
		"aws": {
			"access_key": "${var.aws_access_key}",
			"secret_key": "${var.aws_secret_key}"
		}
	},
	"resource": {
		"aws_instance": {
			"example-instance": {
				"instance_type": "t2.nano",
				"ami": "",
				"tags": {
					"Name": "${var.koding_user_username}-${var.koding_group_slug}"
				},
				"user_data": "echo \"hello world!\" >> /helloworld.txt"
			}
		}
	}
}`)

var StackYAML = []byte(`provider:
  aws:
    access_key: "${var.aws_access_key}"
    secret_key: "${var.aws_secret_key}"
resource:
  aws_instance:
    example-instance:
      instance_type: t2.nano
      ami: ''
      tags:
        Name: "${var.koding_user_username}-${var.koding_group_slug}"
      user_data: echo "hello world!" >> /helloworld.txt`)

var Stack = map[string]interface{}{
	"provider": map[string]interface{}{
		"aws": map[string]interface{}{
			"access_key": "${var.aws_access_key}",
			"secret_key": "${var.aws_secret_key}",
		},
	},
	"resource": map[string]interface{}{
		"aws_instance": map[string]interface{}{
			"example-instance": map[string]interface{}{
				"instance_type": "t2.nano",
				"ami":           "",
				"tags": map[string]interface{}{
					"Name": "${var.koding_user_username}-${var.koding_group_slug}",
				},
				"user_data": "echo \"hello world!\" >> /helloworld.txt",
			},
		},
	},
}
