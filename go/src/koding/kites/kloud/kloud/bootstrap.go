package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/koding/kite"
	"github.com/mitchellh/mapstructure"
)

type AwsBootstrapOutput struct {
	ACL       string `json:"acl" mapstructure:"acl"`
	CidrBlock string `json:"cidr_block" mapstructure:"cidr_block"`
	IGW       string `json:"igw" mapstructure:"igw"`
	KeyPair   string `json:"key_pair" mapstructure:"key_pair"`
	RTB       string `json:"rtb" mapstructure:"rtb"`
	SG        string `json:"sg" mapstructure:"sg"`
	Subnet    string `json:"subnet" mapstructure:"subnet"`
	VPC       string `json:"vpc" mapstructure:"vpc"`
}

type TerraformBootstrapRequest struct {
	// PublicKeys contains publicKeys to be used with terraform
	PublicKeys []string `json:"publicKeys"`

	// Destroy destroys the bootstrap resource associated with the given public
	// keys
	Destroy bool
}

func (k *Kloud) Bootstrap(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformBootstrapRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if len(args.PublicKeys) == 0 {
		return nil, errors.New("publicKeys are not passed")
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	creds, err := fetchCredentials(r.Username, sess.DB, args.PublicKeys)
	if err != nil {
		return nil, err
	}

	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	for _, cred := range creds.Creds {
		// We are going to support more providers in the future, for now only allow aws
		if cred.Provider != "aws" {
			return nil, fmt.Errorf("Bootstrap is only supported for 'aws' provider. Got: '%s'", cred.Provider)
		}

		finalBootstrap, err := appendAWSVariable(awsBootstrap, cred.Data["access_key"], cred.Data["secret_key"])
		if err != nil {
			return nil, err
		}

		// k.Log.Debug("[%s] Final bootstrap:", cred.PublicKey)
		// k.Log.Debug(finalBootstrap)

		// Important so bootstraping is distributed amongs multiple users. If I
		// use these keys to bootstrap, any other user should be not create
		// again, instead they should be fetch and use the existing bootstrap
		// data.
		contentId := sha1sum(cred.Data["access_key"] + cred.Data["secret_key"])

		// TODO(arslan): change this once we have group context name
		groupName := "koding"
		awsOutput := &AwsBootstrapOutput{}

		if args.Destroy {
			k.Log.Info("Destroying bootstrap resources belonging to public key '%s'", cred.PublicKey)
			_, err := tfKite.Destroy(&tf.TerraformRequest{
				Content:   finalBootstrap,
				ContentID: groupName + "-" + contentId,
			})
			if err != nil {
				return nil, err
			}
		} else {
			k.Log.Info("Creating bootstrap resources belonging to public key '%s'", cred.PublicKey)
			state, err := tfKite.Apply(&tf.TerraformRequest{
				Content:   finalBootstrap,
				ContentID: groupName + "-" + contentId,
			})
			if err != nil {
				return nil, err
			}

			k.Log.Debug("[%s] state.RootModule().Outputs = %+v\n", cred.PublicKey, state.RootModule().Outputs)
			if err := mapstructure.Decode(state.RootModule().Outputs, &awsOutput); err != nil {
				return nil, err
			}
		}

		k.Log.Debug("[%s] Aws Output: %+v", cred.PublicKey, awsOutput)
		if err := modelhelper.UpdateCredentialData(cred.PublicKey, bson.M{
			"$set": bson.M{
				"meta.acl":        awsOutput.ACL,
				"meta.cidr_block": awsOutput.CidrBlock,
				"meta.igw":        awsOutput.IGW,
				"meta.key_pair":   awsOutput.KeyPair,
				"meta.rtb":        awsOutput.RTB,
				"meta.sg":         awsOutput.SG,
				"meta.subnet":     awsOutput.Subnet,
				"meta.vpc":        awsOutput.VPC,
			},
		}); err != nil {
			return nil, err
		}
	}

	return true, nil
}

func appendAWSVariable(content, accessKey, secretKey string) (string, error) {
	var data struct {
		Output   map[string]map[string]interface{} `json:"output"`
		Resource map[string]map[string]interface{} `json:"resource"`
		Provider map[string]map[string]interface{} `json:"provider"`
		Variable map[string]map[string]interface{} `json:"variable"`
	}

	if err := json.Unmarshal([]byte(content), &data); err != nil {
		return "", err
	}

	data.Variable["aws_access_key"] = map[string]interface{}{
		"default": accessKey,
	}

	data.Variable["aws_secret_key"] = map[string]interface{}{
		"default": secretKey,
	}

	out, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", err
	}

	return string(out), nil
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
                    "cidr_blocks": [
                        "0.0.0.0/0"
                    ],
                    "from_port": 0,
                    "protocol": "-1",
                    "self": true,
                    "to_port": 65535
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
                "key_name": "kloud-deployment",
                "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYFQFq/DEN0B2YbiZqb3jr+iQphLrzW6svvBjQLUXiKA0P0NfgedvNbqqr2WQcQDKqdZQSHJPccfYYvjyy0wEwD7hq8BDkHTv83nMNxJb3hdmo/ibZmGoUBkw3K7E8fzaWzUDDNSlzBk3UrGayaaLxzOw1LhO5XUfesKNWCg4HzdzjjOklNpJ61iQP4u8JRqXJaOV5RPogHYFDlGXPOaBuDxvOZZanEgaKsfFkwEvpU0km5001XVf8spM7o8f2iEalG9CMF1UVk38/BKBngxSLRyYdP/K0ZdRBSq1syKs8/KPrDWQ6eyqG2cW6Zrb8wb2IDg7Na+PfnUlQn9S+jmF9 hello@koding.com"
            }
        }
    },
    "variable": {
        "aws_region": {
            "description": "Region name in which resources will be created",
            "default": "ap-northeast-1"
        },
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
        }
    }
}`
