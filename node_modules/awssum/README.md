```
 _______           _______  _______           _______ 
(  ___  )|\     /|(  ____ \(  ____ \|\     /|(       )
| (   ) || )   ( || (    \/| (    \/| )   ( || () () |
| (___) || | _ | || (_____ | (_____ | |   | || || || |
|  ___  || |( )| |(_____  )(_____  )| |   | || |(_)| |
| (   ) || || || |      ) |      ) || |   | || |   | |
| )   ( || () () |/\____) |/\____) || (___) || )   ( |
|/     \|(_______)\_______)\_______)(_______)|/     \|

```

NodeJS client libraries for talking to lots of Web Service APIs.

[![Build Status](https://secure.travis-ci.org/appsattic/node-awssum.png?branch=master)](http://travis-ci.org/appsattic/node-awssum)

IRC : Come and say hello in #awssum on Freenode. :)

Btw: [AwsSum is being used](https://twitter.com/andychilton/status/235501828878520321) at
[Medium.com](https://medium.com/)! Yay!

# NEW SITE! #

[AwsSum now has a new docs site](http://awssum.io/). This README.md will eventually disappear in favour of that site.

# How to get AwsSum #

    $ npm -d install awssum

# Example #

```
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var S3 = awssum.load('amazon/s3').S3;

var s3 = new S3({
    'accessKeyId' : accessKeyId,
    'secretAccessKey' : secretAccessKey,
    'region' : amazon.US_EAST_1
});

s3.ListBuckets(function(err, data) {
    if (err) {
        // something went wrong with the request
        console.log(err);
        return;
    }

    // request was fine
    console.log(data);
});

s3.CreateBucket({ BucketName : 'my-bucket' }, function(err, data) {
    if (err) {
        console.log(err);
        return;
    }

    // creation of bucket was ok, now let's put an object into it
    s3.PutObject({
        BucketName : 'my-bucket',
        ObjectName : 'some.txt',
        ContentLength : '14',
        Body          : "Hello, World!\n",
    }, function(err, data) {
        console.log(err)
        console.log(data)
    });
});
```

# What services does 'node-awssum' talk to? #

Currently AwsSum has coverage of the following services:

<table>
  <thead>
    <tr>
      <th>Company</th>
      <th>Service</th>
      <th>SignatureMethod</th>
      <th>Signature</th>
      <th>Operations</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Amazon</td>
      <td>SimpleDB</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>10/10 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>SQS</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>15/15 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>SES</td>
      <td>X-Amzn-Authorization &quot;AWS3-HTTPS&quot; header, (HmacSHA256)</td>
      <td>✔</td>
      <td>18/18 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>SNS</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>15/15 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>S3</td>
      <td>Authorization &quot;AWS&quot; header (SHA1)</td>
      <td>✔</td>
      <td>43/43 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>EC2</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>134/134 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Route53</td>
      <td>X-Amzn-Authorization &quot;AWS3-HTTPS&quot; header, (HmacSHA256)</td>
      <td>✔</td>
      <td>7/7 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>ElastiCache</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>21/21 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>CloudFront</td>
      <td>Authorization &quot;AWS&quot; header (sha1)</td>
      <td>✔</td>
      <td>21/21 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Elastic Load Balancing (ELB)</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>23/23 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>DynamoDB</td>
      <td>X-Amzn-Authorization &quot;AWS3&quot; (HmacSHA256)</td>
      <td>✔</td>
      <td>13/13 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Simple Workflow Service</td>
      <td>X-Amzn-Authorization &quot;AWS3&quot; (HmacSHA256)</td>
      <td>✔</td>
      <td>31/31 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Flexible Payments Service (FPS)</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>22/22 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>CloudWatch</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>11/11 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Identity and Access Management (IAM)</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>69/69 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Relational Database Service (RDS)</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>39/39 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>CloudFormation</td>
      <td>Signature v2, (HmacSHA256)</td>
      <td>✔</td>
      <td>12/12 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Instance MetaData (IMD)</td>
      <td>[none]</td>
      <td>✔</td>
      <td>2/2 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>ElasticBeanstalk</td>
      <td>Signature v2, (Hmac256)</td>
      <td>✔</td>
      <td>29/29 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>AutoScaling</td>
      <td>Signature v2, (Hmac256)</td>
      <td>✔</td>
      <td>33/33 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Import/Export</td>
      <td>Signature v2, (Hmac256)</td>
      <td>✔</td>
      <td>5/5 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Elastic MapReduce (EMR)</td>
      <td>Signature v2, (Hmac256)</td>
      <td>✔</td>
      <td>7/7 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Storage Gateway</td>
      <td>Signature v4, (Hmac256)</td>
      <td>✔</td>
      <td>26/26 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>CloudSearch (CS)</td>
      <td>Signature v4, (Hmac256)</td>
      <td>✔</td>
      <td>20/20 (100%)</td>
    </tr>
    <tr>
      <td></td>
      <td>Glacier</td>
      <td>Signature v4, (Hmac256)</td>
      <td>✔</td>
      <td>19/19 (100%)</td>
    </tr>

    <tr>
      <td>Twitter</td>
      <td>Twitter</td>
      <td>OAuth 1.0a</td>
      <td>✔</td>
      <td>98/101</td>
    </tr>

    <tr>
      <td>Tumblr</td>
      <td>Tumblr</td>
      <td>OAuth 1.0a</td>
      <td>✔</td>
      <td>0/???</td>
    </tr>

    <tr>
      <td>Xero</td>
      <td>Xero</td>
      <td>OAuth 1.0a</td>
      <td>✔</td>
      <td>~12/~40?</td>
    </tr>

    <tr>
      <td>Yahoo!</td>
      <td>Contacts</td>
      <td>OAuth 1.0a</td>
      <td>✔</td>
      <td>3/???</td>
    </tr>

  </tbody>
</table>

In future releases we will be targeting (in no particular order):

* AWS:
    * Mechanical Turk ([Request or Sponsor Development][sponsor])
    * Marketplace Web Services ([Request or Sponsor Development][sponsor])
* RackspaceCloud:
    * Servers ([Request or Sponsor Development][sponsor])
    * Files ([Request or Sponsor Development][sponsor])
    * LoadBalances ([Request or Sponsor Development][sponsor])
    * DNS ([Request or Sponsor Development][sponsor])
* Flickr ([Request or Sponsor Development][sponsor])
* PayPal ([Request or Sponsor Development][sponsor])
* some Google services ([Request or Sponsor Development][sponsor])
* URL shorteners ([Request or Sponsor Development][sponsor])
* anything else you'd like? ([Request or Sponsor Development][sponsor])

There are lots of services out there, so please [Request or Sponsor Development][sponsor] if you'd like one
implemented.

# What 'node-awssum' is? #

node-awssum is an abstraction layer to many web service APIs. It abstracts out the service endpoints, the HTTP verbs to
use, what headers and parameters to set, how to sign the request and finally how to decode the result. It let's you
pass a data structure in and get a data structure out. It also helps in the odd small way when dealing with complex
input such as creating XML (e.g. Amazon S3), JSON data structures (e.g. Amazon SQS) or parameters with lots of values
(e.g. Amazon SimpleDB).

In saying this, there are some web service operations that are inherently nasty and since node-awssum is essentially a
proxy to the operation itself it can't abstract away all nastiness.

For an example of where node-awssum helps is when creating a Bucket in Amazon S3. We take a single 'LocationConstraint'
parameter in the 'createBucket' call and node-awssum takes that and builds (the horrible) XML which it needs to send
with the request. This makes it much easier to perform calls to the various web services and their individual
operations since this simple notion is across all web services.

However, there are also examples of where node-awssum can't really help make the operation nicer. Many of the Amazon
Web Services return XML which we blindly convert to a data structure and return that to the caller. In these cases we
don't perform any kind of manipulation or conversion to a canonical structure to make the returned data nicer. In these
cases, a small library which sits on top of node-awssums libraries may be a good choice (see *winston-simpledb* for an
example of this - http://github.com/appsattic/winston-simpledb). This would be especially true for SimpleDB where the
higher level library could perform number padding, date conversions, creation of multi-field indexes and default field
values - none of which node-awssum does.

# Examples #

Example 1. This is what node-awssum looks like when adding a topic to Amazon's Simple Notification Service:

``` js
sns.CreateTopic({ TopicName : 'my-topic' })
=>  {
        Headers: {
            date: 'Wed, 16 May 2012 10:32:24 GMT',
            content-type: 'text/xml',
            x-amzn-requestid: '6d099dcd-9f42-11e1-a8a2-0f9b48899c6b',
            content-length: '315'
        },
        Body: {
            CreateTopicResponse: {
                @: {
                    xmlns: 'http://sns.amazonaws.com/doc/2010-03-31/'
                },
                ResponseMetadata: {
                    RequestId: '6d099dcd-9f42-11e1-a8a2-0f9b48899c6b'
                },
                CreateTopicResult: {
                    TopicArn: 'arn:aws:sns:us-east-1:616781752028:my-topic'
                }
            }
        },
        StatusCode: 200
    }
```

What you would probably like to do is the following (with an example SNS Wrapper Library):

``` js
snsWrapperLibrary.createTopic('my-topic')
=>  arn:aws:sns:us-east-1:616781752028:my-topic
```

This is pretty easy to do but annoying to have to find and extract the information you really want. node-awssum comes
with some example libraries. :)

Example 2. Saving some attributes for AWS SimpleDB.

...

# What is 'node-awssum' for? #

This library has a number of uses but mostly it should be used from within a more friendly wrapper library. Let's look
at some examples.

Example 1: A SimpleDB Wrapper library. Since node-awssum doesn't do any kind of conversion of the values you want to
put into SimpleDB, it would make sense that you used a library which did those conversions for you, such as padding
integer values, normalising dates into an ISO string, setting defaults or helping with queries.

Example 2: When using Amazon Route53, you sometimes have to do a request, manipulate what you got back and then send a
new bit of data. Instead a wrapper library around node-awssum which just helps you add or delete resource records would
be much easier to use.

Example 3: A small wrapper around the Simple Queue Service means you could simply have some commands such as send(...),
receive() and delete() would make using the service a breeze.

The reason for this is because the data structures it receives, and more especially those it returns, are far too
complicated for dealing with them in your main program. Therefore in general, a wrapper library around these simple
operations would make each service easier to use.

# How to use it #

This library provides basic client functionality to each of these services. It's pretty simple but this means it's also
quite powerful. In general you wouldn't use these libraries directly (though there is nothing stopping you making the
odd call here and there, especially when setting your environment up) but instead you would use them via a more
friendly API via a wrapper library.

You can use this library in your programs and applications, but it can also be built on for more
user-friendly (from the perspective of the programmer) wrapper libraries.

Essentially it's a "data in, data out" kinda library without too many bells and whistles. It doesn't really check what
you pass it, apart from when a parameter is required. As I sa

As a quick example, to create a domain in AWS SimpleDB:

``` js
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var SimpleDB = awssum.load('amazon/simpledb').SimpleDB;

var sdb = new SimpleDB({
    'accessKeyId'     : 'my-access-key-id',
    'secretAccessKey' : 'my-secret-access-key',
    // 'awsAccountId'    : 'my-aws-account-id', // optional
    'region'          : amazon.US_EAST_1
});

sdb.CreateDomain({ DomainName : 'test' }, function(err, data) {
    console.log('Error :', err);
    console.log('Data  :', data);
});
```

A successful run puts the pertinent information into 'data' ('err' is undefined). An unsuccessful run results in a value
in 'err' but nothing in 'data'.

# Author #

Written by [Andrew Chilton](http://chilts.org/) - [Blog](http://chilts.org/blog/) - [Twitter](https://twitter.com/andychilton).

# License #

The MIT License : http://opensource.org/licenses/MIT

Copyright (c) 2011-2012 AppsAttic Ltd. http://appsattic.com/

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[sponsor]: mailto:chilts%40appsattic.com
