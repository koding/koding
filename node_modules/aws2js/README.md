## About

Amazon Web Services node.js module. Originally a fork of [aws-lib](https://github.com/livelycode/aws-lib/).

 * [Changelog](https://github.com/SaltwaterC/aws2js/blob/master/doc/CHANGELOG.md)
 * [License](https://github.com/SaltwaterC/aws2js/blob/master/doc/LICENSE.md)

## Installation

Either manually clone this repository into your node_modules directory, then run `npm install` on the aws2js top directory, or the recommended method:

> npm install aws2js

[npm](https://github.com/isaacs/npm) is a direct dependency of this library. It is used programmatically to install the dependencies for XML and MIME parsing.

By default, the module installs as dependencies the [libxml-to-js](https://github.com/SaltwaterC/libxml-to-js) and the [mime-magic](https://github.com/SaltwaterC/mime-magic) libraries. Under Windows, it installs by default with [xml2js](https://github.com/Leonidas-from-XIV/node-xml2js) and mime-magic.

Basically, under Windows the default installation is the equivalent of:

> npm install aws2js --xml2js true

If you want to install the library without binary dependencies, you can issue this npm command:

> npm install aws2js --xml2js true --mime true

This installs the library with xml2js and [mime](https://github.com/broofa/node-mime) as dependencies. Please notice that the mime library detects the MIME type by doing a file extension lookup, while mime-magic does it the proper way by wrapping the functionality of libmagic. You have been warned.

The '--xml2js true' and '--mime true' are boolean flags, therefore you may use them in any combination, if applicable.

In order to use these flags when this package is referenced from a package.json file, the recommendations are:

 * edit the ~/.npmrc file, add these values xml2js = true and / or mime = true
 * define the appropriate environment variables: npm_config_xml2js=true and / or npm_config_mime=true

The above methods are equivalent. You need to pick just one.

## Project and Design goals

 * HTTPS-only APIs communication (exceptions allowed for HTTP-only APIs)
 * Proper error reporting
 * Simple to write clients for a specific AWS service (abstracts most of the low level plumbing)
 * Simple to use AWS API calls
 * Higher level clients for specific work flows
 * Proper documentation

## Supported Amazon Web Services

 * [Amazon EC2](https://github.com/SaltwaterC/aws2js/wiki/EC2-Client) (Elastic Compute Cloud)
 * [Amazon RDS](https://github.com/SaltwaterC/aws2js/wiki/RDS-Client) (Relational Database Service)
 * [Amazon SES](https://github.com/SaltwaterC/aws2js/wiki/SES-Client) (Simple Email Service)
 * [Amazon ELB](https://github.com/SaltwaterC/aws2js/wiki/ELB-Client) (Elastic Load Balancing)
 * [Amazon IAM](https://github.com/SaltwaterC/aws2js/wiki/IAM-Client) (Identity and Access Management)
 * [Amazon Auto Scaling](https://github.com/SaltwaterC/aws2js/wiki/Auto-Scaling-Client)
 * [Amazon CloudWatch](https://github.com/SaltwaterC/aws2js/wiki/CloudWatch-Client)
 * [Amazon ElastiCache](https://github.com/SaltwaterC/aws2js/wiki/ElastiCache-Client)
 * [Amazon SQS](https://github.com/SaltwaterC/aws2js/wiki/SQS-Client) (Simple Queue Service)
 * [Amazon CloudFormation](https://github.com/SaltwaterC/aws2js/wiki/CloudFormation-Client)
 * [Amazon SDB](https://github.com/SaltwaterC/aws2js/wiki/SDB-Client) (SimpleDB)
 * [Amazon STS](https://github.com/SaltwaterC/aws2js/wiki/STS-Client) (Security Token Service)
 * [Amazon DynamoDB](https://github.com/SaltwaterC/aws2js/wiki/DynamoDB-Client)
 * [Amazon SNS](https://github.com/SaltwaterC/aws2js/wiki/SNS-Client) (Simple Notification Service)
 * [Amazon EMR](https://github.com/SaltwaterC/aws2js/wiki/EMR-Client) (Elastic MapReduce)
 * [Amazon S3](https://github.com/SaltwaterC/aws2js/wiki/S3-Client) (Simple Storage Service)

## Contributions

For the moment, this project is largely a one man show. Bear with me if things don't move as fast as they should. There are a handful of [aws2js contributors](https://github.com/SaltwaterC/aws2js/blob/master/doc/CONTRIBUTORS.md) as well. The community makes things to be better for everyone.

If you'd like to contribute your line of code (or more), please send a pull request against the future branch. This makes things to be easier on my side. Feature branches are also acceptable. Even commits in your master branch are acceptable. I don't rely on GitHub's merge functionality as I always pull from remotes and manually issue the merge command.

I ask you to patch against the future branch since that's the place where all the development happens, therefore it should be the least conflicts when merging your code. I use the master only for integrating the releases. The master branch always contains the latest stable release.
