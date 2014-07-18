AWS        = require 'aws-sdk'
AWS.config.region = 'us-east-1a'
AWS.config.update
	accessKeyId			: 'AKIAI7RHT42HWAA652LA'
	secretAccessKey	: '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'



ec2 = new AWS.EC2()
# params =
#   ImageId: "ami-1624987f" # Amazon Linux AMI x86_64 EBS
#   InstanceType: "t1.micro"
#   MinCount: 1
#   MaxCount: 1

# console.log JSON.stringify ec2


params =
  ImageId: "ami-a6926dce" # Amazon ubuntu 14.04
  InstanceType: "m3.xlarge"
  MinCount: 1
  MaxCount: 1
  Monitoring:
  	Enabled : no
  NetworkInterfaces :
  	PrivateIpAddresses :
  		PrivateIpAddress : '10.0.0.10'


# Create the instance
ec2.runInstances params, (err, data) ->
  if err
    return console.log "Could not create instance", err

  instanceId = data.Instances[0].InstanceId
  console.log "Created instance", instanceId

  # Add tags to the instance
  params =
    Resources: [instanceId]
    Tags: [
      Key: "devrims instance"
      Value: instanceName
    ]

  ec2.createTags params, (err) ->
    console.log "Tagging instance", (if err then "failure" else "success")

console.log ec2