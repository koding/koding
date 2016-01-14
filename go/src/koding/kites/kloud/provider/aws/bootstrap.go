package awsprovider

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	awssession "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/iam"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

// Bootstrap
func (s *Stack) Bootstrap(ctx context.Context) (interface{}, error) {
	var arg kloud.BootstrapRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	if arg.Destroy {
		s.Log.Debug("Bootstrap destroy is called")
	} else {
		s.Log.Debug("Bootstrap apply is called")
	}

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, arg.GroupName, arg.Identifiers); err != nil {
		return nil, err
	}

	s.Log.Debug("Connecting to terraformer kite")

	tfKite, err := terraformer.Connect(s.Session.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	s.Log.Debug("Iterating over credentials")

	for _, cred := range s.Builder.Credentials {
		// We are going to support more providers in the future, for now only allow aws
		if cred.Provider != "aws" {
			return nil, fmt.Errorf("Bootstrap is only supported for 'aws' provider. Got: '%s'", cred.Provider)
		}

		s.Log.Debug("parsing the template")

		if err := s.Builder.BuildTemplate(awsBootstrap); err != nil {
		}

		meta := cred.Meta.(*AwsMeta)

		sess := awssession.New(&aws.Config{
			Credentials: credentials.NewStaticCredentials(meta.AccessKey, meta.SecretKey, ""),
			Region:      aws.String(meta.Region),
		})

		iamClient := iam.New(sess)

		s.Log.Debug("Fetching the AWS user information to get the account ID")
		user, err := iamClient.GetUser(nil) // will default to username making the request
		if err != nil {
			return nil, err
		}

		awsAccountID, err := stackplan.ParseAccountID(aws.StringValue(user.User.Arn))
		if err != nil {
			return nil, err
		}

		contentID := fmt.Sprintf("%s-%s-%s", awsAccountID, arg.GroupName, meta.Region)
		s.Log.Debug("Going to use the contentID: %s", contentID)

		keyName := "koding-deployment-" + s.Req.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)

		finalBootstrap, err := s.Builder.Template.JsonOutput()
		if err != nil {
			return nil, err
		}

		finalBootstrap, err = appendAWSTemplateData(finalBootstrap, &awsTemplateData{
			KeyPairName:     keyName,
			PublicKey:       s.Keys.PublicKey,
			EnvironmentName: fmt.Sprintf("Koding-%s-Bootstrap", arg.GroupName),
		})

		s.Log.Debug("Final bootstrap template:")
		s.Log.Debug(finalBootstrap)

		if err != nil {
			return nil, err
		}

		// s.Log.Debug("[%s] Final bootstrap:", cred.Identifier)
		// s.Log.Debug(finalBootstrap)

		// Important so bootstraping is distributed amongs multiple users. If I
		// use these keys to bootstrap, any other user should be not create
		// again, instead they should be fetch and use the existing bootstrap
		// data.

		resp := &AwsMeta{}

		// this is custom because we need to remove the fields if we get a
		// destroy. So the operator changes from $set to $unset.
		mongodDBOperator := "$set"

		if arg.Destroy {
			mongodDBOperator = "$unset"
			s.Log.Info("Destroying bootstrap resources belonging to identifier '%s'", cred.Identifier)
			_, err := tfKite.Destroy(&tf.TerraformRequest{
				Content:   finalBootstrap,
				ContentID: contentID,
			})
			if err != nil {
				return nil, err
			}
		} else {
			s.Log.Info("Creating bootstrap resources belonging to identifier '%s'", cred.Identifier)
			state, err := tfKite.Apply(&tf.TerraformRequest{
				Content:   finalBootstrap,
				ContentID: contentID,
			})
			if err != nil {
				return nil, err
			}

			s.Log.Debug("[%s] state.RootModule().Outputs = %+v\n", cred.Identifier, state.RootModule().Outputs)

			if err := s.Builder.Object.Decode(state.RootModule().Outputs, resp); err != nil {
				return nil, err
			}

			s.Log.Debug("[%s] resp = %+v\n", cred.Identifier, resp)

			if !resp.IsBootstrapComplete() {
				return nil, errors.New("Bootstrap metadata is incomplete: " + cred.Identifier)
			}
		}

		s.Log.Debug("[%s] Bootstrap response: %+v", cred.Identifier, resp)

		if err := modelhelper.UpdateCredentialData(cred.Identifier, bson.M{
			mongodDBOperator: bson.M{
				"meta.acl":        resp.ACL,
				"meta.cidr_block": resp.CidrBlock,
				"meta.igw":        resp.IGW,
				"meta.key_pair":   resp.KeyPair,
				"meta.rtb":        resp.RTB,
				"meta.sg":         resp.SG,
				"meta.subnet":     resp.Subnet,
				"meta.vpc":        resp.VPC,
				"meta.ami":        resp.AMI,
			},
		}); err != nil {
			return nil, err
		}
	}

	return true, nil
}

func appendAWSTemplateData(template string, awsData *awsTemplateData) (string, error) {
	var data struct {
		Output   map[string]map[string]interface{} `json:"output,omitempty"`
		Resource map[string]map[string]interface{} `json:"resource,omitempty"`
		Provider map[string]map[string]interface{} `json:"provider,omitempty"`
		Variable map[string]map[string]interface{} `json:"variable,omitempty"`
	}

	if err := json.Unmarshal([]byte(template), &data); err != nil {
		return "", err
	}

	data.Variable["key_name"] = map[string]interface{}{
		"default": awsData.KeyPairName,
	}

	data.Variable["public_key"] = map[string]interface{}{
		"default": awsData.PublicKey,
	}

	data.Variable["environment_name"] = map[string]interface{}{
		"default": awsData.EnvironmentName,
	}

	out, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", err
	}

	return string(out), nil
}

// awsTemplateData is being used to format the bootstrap before we pass it to
// terraformer
type awsTemplateData struct {
	KeyPairName     string
	PublicKey       string
	EnvironmentName string
}

var awsBootstrap = `{
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}",
            "region": "${var.aws_region}"
        }
    },
    "output": {
        "vpc": {
            "value": "${aws_vpc.vpc.id}"
        },
        "cidr_block": {
            "value": "${aws_vpc.vpc.cidr_block}"
        },
        "rtb": {
            "value": "${aws_vpc.vpc.main_route_table_id}"
        },
        "acl": {
            "value": "${aws_vpc.vpc.default_network_acl_id}"
        },
        "igw": {
            "value": "${aws_internet_gateway.main_vpc_igw.id}"
        },
        "subnet": {
            "value": "${aws_subnet.main_koding_subnet.id}"
        },
        "sg": {
            "value": "${aws_security_group.allow_all.id}"
        },
        "ami": {
            "value": "${lookup(var.aws_amis, var.aws_region)}"
        },
        "key_pair": {
            "value": "${aws_key_pair.koding_key_pair.key_name}"
        }
    },
    "resource": {
        "aws_vpc": {
            "vpc": {
                "cidr_block": "${var.cidr_block}",
                "tags": {
                    "Name": "${var.environment_name}"
                }
            }
        },
        "aws_internet_gateway": {
            "main_vpc_igw": {
                "tags": {
                    "Name": "${var.environment_name}"
                },
                "vpc_id": "${aws_vpc.vpc.id}"
            }
        },
        "aws_subnet": {
            "main_koding_subnet": {
                "availability_zone": "${lookup(var.aws_availability_zones, var.aws_region)}",
                "cidr_block": "${var.cidr_block}",
                "map_public_ip_on_launch": true,
                "tags": {
                    "Name": "${var.environment_name}",
                    "subnet": "public"
                },
                "vpc_id": "${aws_vpc.vpc.id}"
            }
        },
        "aws_route_table": {
            "public": {
                "route": {
                    "cidr_block": "0.0.0.0/0",
                    "gateway_id": "${aws_internet_gateway.main_vpc_igw.id}"
                },
                "tags": {
                    "Name": "${var.environment_name}",
                    "routeTable": "koding",
                    "subnet": "public"
                },
                "vpc_id": "${aws_vpc.vpc.id}"
            }
        },
        "aws_route_table_association": {
            "public-1": {
                "route_table_id": "${aws_route_table.public.id}",
                "subnet_id": "${aws_subnet.main_koding_subnet.id}"
            }
        },
        "aws_security_group": {
            "allow_all": {
                "description": "Allow all inbound and outbound traffic",
                "ingress": {
                    "from_port": 0,
                    "to_port": 0,
                    "protocol": "-1",
                    "cidr_blocks": ["0.0.0.0/0"],
                    "self": true
                },
                "egress": {
                    "from_port": 0,
                    "to_port": 0,
                    "protocol": "-1",
                    "self": true,
                    "cidr_blocks": ["0.0.0.0/0"]
                },
                "name": "allow_all",
                "tags": {
                    "Name": "${var.environment_name}"
                },
                "vpc_id": "${aws_vpc.vpc.id}"
            }
        },
        "aws_key_pair": {
            "koding_key_pair": {
                "key_name": "${var.key_name}",
                "public_key": "${var.public_key}"
            }
        }
    },
    "variable": {
        "cidr_block": {
            "default": "10.0.0.0/16"
        },
        "environment_name": {
            "default": "Koding-Bootstrap"
        },
        "aws_availability_zones": {
            "default": {
                "ap-northeast-1": "ap-northeast-1b",
                "ap-southeast-1": "ap-southeast-1b",
                "ap-southeast-2": "ap-southeast-2b",
                "eu-central-1": "eu-central-1b",
                "eu-west-1": "eu-west-1b",
                "sa-east-1": "sa-east-1b",
                "us-east-1": "us-east-1b",
                "us-west-1": "us-west-1b",
                "us-west-2": "us-west-2b"
            }
        },
        "aws_amis": {
            "default": {
                "ap-northeast-1": "ami-9e5cff9e",
                "ap-southeast-1": "ami-ec7879be",
                "ap-southeast-2": "ami-2fce8b15",
                "eu-central-1": "ami-60f9c27d",
                "eu-west-1": "ami-7c4b0a0b",
                "sa-east-1": "ami-cd9518d0",
                "us-east-1": "ami-cf35f3a4",
                "us-west-1": "ami-b33dccf7",
                "us-west-2": "ami-8d5b5dbd"
            }
        }
    }
}`
