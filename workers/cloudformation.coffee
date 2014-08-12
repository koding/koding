
{Deploy, Release, AWS, cf} = require "./install/deploy.coffee"

argv             = require('minimist')(process.argv.slice(2))
eden             = require 'node-eden'
log                = console.log
timethat     = require 'timethat'
Connection = require "ssh2"
fs                 = require 'fs'
semver         = require 'semver'
{exec}         = require 'child_process'
request        = require 'request'
ec2                = new AWS.EC2()
elb                = new AWS.ELB()

cloudformation =
    AWSTemplateFormatVersion: "2010-09-09"
    Description: "Koding deployment on AWS"
    Resources:
        CoreOSServerAutoScale:
            Type: "AWS::AutoScaling::AutoScalingGroup"
            Properties:
                AvailabilityZones: ["us-east-1a"]
                LaunchConfigurationName: Ref: "KodingLaunchConfig"
                VPCZoneIdentifier: [Ref: "SubnetId"]
                MinSize: "3"
                MaxSize: "12"
                DesiredCapacity: Ref: "ClusterSize"
                Tags: [ Key: "Name", Value: {Ref: "AWS::StackName"}, PropagateAtLaunch: true]

        KodingLaunchConfig:
            Type: "AWS::AutoScaling::LaunchConfiguration"
            Properties:
                ImageId:
                    "Fn::FindInMap": [
                        "RegionMap"
                        {
                            Ref: "AWS::Region"
                        }
                        "AMI"
                    ]

                InstanceType:
                    Ref: "InstanceType"

                KeyName:
                    Ref: "KeyPair"

                SecurityGroups: [Ref: "SecurityGroupId"]
                UserData:
                    "Fn::Base64":
                        "Fn::Join": [
                            ""
                            [
                                """#cloud-config

                                coreos:
                                    etcd:
                                        discovery: """
                                {
                                    Ref: "DiscoveryURL"
                                }
                                "\n"
                                "        addr: $"
                                {
                                    Ref: "AdvertisedIPAddress"
                                }
                                "_ipv4:4001\n"
                                "        peer-addr: $"
                                {
                                    Ref: "AdvertisedIPAddress"
                                }
                                "_ipv4:7001\n"
                                "    units:\n"
                                "        - name: etcd.service\n"
                                "            command: start\n"
                                "        - name: fleet.service\n"
                                "            command: start\n"
                            ]
                        ]
