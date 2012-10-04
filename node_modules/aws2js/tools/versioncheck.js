#!/usr/bin/env node

'use strict';

// Checks the AWS docs for newer API versions

var http = require('http-get');

var docs = {
	ec2: 'http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/Welcome.html',
	rds: 'http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/Welcome.html',
	ses: 'http://docs.amazonwebservices.com/ses/latest/APIReference/Welcome.html',
	elb: 'http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/APIReference/Welcome.html',
	iam: 'http://docs.amazonwebservices.com/IAM/latest/APIReference/Welcome.html',
	autoscaling: 'http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/Welcome.html',
	cloudwatch: 'http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/Welcome.html',
	elasticache: 'http://docs.amazonwebservices.com/AmazonElastiCache/latest/APIReference/Welcome.html',
	sqs: 'http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/APIReference/Welcome.html',
	cloudformation: 'http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/Welcome.html',
	sdb: 'http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/Welcome.html',
	sts: 'http://docs.amazonwebservices.com/STS/latest/APIReference/Welcome.html',
	dynamodb: 'http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/Introduction.html',
	sns: 'http://docs.amazonwebservices.com/sns/latest/api/Welcome.html',
	emr: 'http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/Welcome.html'
};

var config = require('../config/aws.js');

var check = function (service, url, current) {
	http.get({url: url}, function (err, res) {
		if (err) {
			console.error('The %s service returned error: %s', service, err.message);
		} else {
			var version = res.buffer.match(/API Version (\d{4}-\d{2}-\d{2})/);
			if (version && version[1]) {
				if (version[1] != current) {
					console.log('%s has a newer version: %s', service, version[1]);
				} else {
					if (process.env.debug) {
						console.error('%s has the same version: %s', service, version[1]);
					}
				}
			} else {
				console.error('Did not find a version for: %s', service);
			}
		}
	});
};

var service;
for (service in docs) {
	if (docs.hasOwnProperty(service)) {
		check(service, docs[service], config.clients[service].query.Version);
	}
}
