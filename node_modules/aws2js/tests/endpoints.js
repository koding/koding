'use strict';

var assert = require('assert');
var aws = require('../');
var config = require('../config/aws.js');
var suffix = config.suffix; 

var clients = {
	ec2: config.clients.ec2.prefix,
	rds: config.clients.rds.prefix,
	elb: config.clients.elb.prefix,
	cloudwatch: config.clients.cloudwatch.prefix,
	sdb: config.clients.sdb.prefix
};

var client;
for (client in clients) {
	if (clients.hasOwnProperty(client)) {
		var prefix = clients[client];
		var cl = aws.load(client);
		assert.deepEqual(cl.getEndPoint(), prefix + suffix);
		cl.setRegion('eu-west-1');
		assert.deepEqual(cl.getEndPoint(), prefix + '.eu-west-1' + suffix);
	}
}

var ses = aws.load('ses');
assert.deepEqual(ses.getEndPoint(), 'email.us-east-1' + suffix);

var iam = aws.load('iam');
assert.deepEqual(iam.getEndPoint(), 'iam' + suffix);

var autoscaling = aws.load('autoscaling');
assert.deepEqual(autoscaling.getEndPoint(), 'autoscaling.us-east-1' + suffix);
autoscaling.setRegion('us-west-1');
assert.deepEqual(autoscaling.getEndPoint(), 'autoscaling.us-west-1' + suffix);

var ec = aws.load('elasticache');
assert.deepEqual(ec.getEndPoint(), 'elasticache.us-east-1' + suffix);

var sqs = aws.load('sqs');
assert.deepEqual(sqs.getEndPoint(), 'queue' + suffix);
sqs.setRegion('us-west-1');
assert.deepEqual(sqs.getEndPoint(), 'sqs.us-west-1' + suffix);

var cf = aws.load('cloudformation');
assert.deepEqual(cf.getEndPoint(), 'cloudformation.us-east-1' + suffix);
cf.setRegion('us-west-1');
assert.deepEqual(cf.getEndPoint(), 'cloudformation.us-west-1' + suffix);

var ddb = aws.load('dynamodb');
assert.deepEqual(ddb.getEndPoint(), 'dynamodb.us-east-1' + suffix);

var sts = aws.load('sts');
assert.deepEqual(sts.getEndPoint(), 'sts' + suffix);

var sns = aws.load('sns');
assert.deepEqual(sns.getEndPoint(), 'sns.us-east-1' + suffix);
sns.setRegion('us-west-1');
assert.deepEqual(sns.getEndPoint(), 'sns.us-west-1' + suffix);

var emr = aws.load('emr');
assert.deepEqual(emr.getEndPoint(), 'elasticmapreduce.us-east-1' + suffix);
emr.setRegion('us-west-1');
assert.deepEqual(emr.getEndPoint(), 'elasticmapreduce.us-west-1' + suffix);

var s3 = aws.load('s3');
assert.deepEqual(s3.getEndPoint(), 's3' + suffix);
s3.setBucket('foo');
assert.deepEqual(s3.getEndPoint(), 'foo.s3' + suffix);
s3.setEndPoint('bar');
assert.deepEqual(s3.getEndPoint(), 'bar.s3' + suffix);
