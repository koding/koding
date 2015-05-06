package terraformer

var SampleTFJSON = `{
    "output": {
        "vpc_id": {
            "value": "${aws_vpc.vpc.id}"
        },
        "cidr_block": {
            "value": "${aws_vpc.vpc.cidr_block}"
        },
        "route_table_id": {
            "value": "${aws_vpc.vpc.main_route_table_id}"
        },
        "default_network_acl_id": {
            "value": "${aws_vpc.vpc.default_network_acl_id}"
        },
        "default_security_group_id": {
            "value": "${aws_vpc.vpc.default_security_group_id}"
        },
        "aws_internet_gateway_id": {
            "value": "${aws_internet_gateway.main_vpc_igw.id}"
        },
        "aws_main_koding_subnet": {
            "value": "${aws_subnet.main_koding_subnet.id}"
        },
        "security_group_id_web": {
            "value": "${aws_security_group.allow_all.id}"
        },
        "koding_key_pair_name": {
            "value": "${aws_key_pair.koding_key_pair.key_name}"
        }
    },
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "region": "${var.aws_region}",
            "secret_key": "${var.aws_secret_key}"
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
                    "routeTable": "test",
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
                    "cidr_blocks": ["0.0.0.0/0"],
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
                "key_name": "koding_key_pair",
                "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8u3tdgzNBq51ZNK0zXW1FziMU90drNgvY8uLi/zNOL1QuBwbRMNNGj/1ZyZmY+hV3VdmexA9AxsOofWEyvzUtL/hkJCmYglWGnTtIawOyDqTXi8Wjz4d00WW69zOiQqpAIAah5ejVsq9gpHslBy4amU+ExcxYoMYoz3ozccim++HkovLr9EhctfJuWvoPtrqljg4D9bn10eR0gdKNROxpnHPfX/Ge7NGcYAsvod5GsUI5zOV3lGfqJTKs+N1jxuqPVUKhoDiEimUQ4SoxBDneETdhRCZRVIQV7cwTfgw+kF58DqgTJCbwzyTyl9n7827Qi1Ha38oWhkAK+cB3uUgT cihangir@koding.com"
            }
        }
    },
    "variable": {
        "aws_region": {
            "description": "Region name in which resources will be created"
        },
        "aws_secret_key": {
            "description": "AWS Secret key"
        },
        "aws_access_key": {
            "description": "AWS Access key"
        },
        "cidr_block": {
            "default": "10.0.0.0/16"
        },
        "environment_name": {
            "default": "kodingterraformtest"
        },
        "aws_availability_zones": {
            "default": {
                "sa-east-1": "sa-east-1a"
            }
        },
        "koding_test_instance_amis": {
            "default": {
                "sa-east-1": "ami-cf43f9d2"
            }
        }
    }
}
`
