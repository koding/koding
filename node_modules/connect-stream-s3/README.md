```
 _______  _______  _        _        _______  _______ _________
(  ____ \(  ___  )( (    /|( (    /|(  ____ \(  ____ \\__   __/
| (    \/| (   ) ||  \  ( ||  \  ( || (    \/| (    \/   ) (   
| |      | |   | ||   \ | ||   \ | || (__    | |         | |   
| |      | |   | || (\ \) || (\ \) ||  __)   | |         | |   
| |      | |   | || | \   || | \   || (      | |         | |   
| (____/\| (___) || )  \  || )  \  || (____/\| (____/\   | |   
(_______/(_______)|/    )_)|/    )_)(_______/(_______/   )_(   
                                                               

            _______ _________ _______  _______  _______  _______ 
           (  ____ \\__   __/(  ____ )(  ____ \(  ___  )(       )
           | (    \/   ) (   | (    )|| (    \/| (   ) || () () |
     _____ | (_____    | |   | (____)|| (__    | (___) || || || |
    (_____)(_____  )   | |   |     __)|  __)   |  ___  || |(_)| |
                 ) |   | |   | (\ (   | (      | (   ) || |   | |
           /\____) |   | |   | ) \ \__| (____/\| )   ( || )   ( |
           \_______)   )_(   |/   \__/(_______/|/     \||/     \|
                                                                 

                _______  ______  
               (  ____ \/ ___  \ 
               | (    \/\/   \  \
         _____ | (_____    ___) /
        (_____)(_____  )  (___ ( 
                     ) |      ) \
               /\____) |/\___/  /
               \_______)\______/ 
                                 
```

Streaming connect middleware for uploading files to Amazon S3.

Uses the awesome [AwsSum](https://github.com/appsattic/node-awssum/) for Amazon Web Services goodness.

# How to get it #

    $ npm -d install connect-stream-s3

## Example ##

```
var express = require('express');
var connectStreamS3 = require('connect-stream-s3');
var amazon = require('awssum').load('amazon/amazon');

// give each uploaded file a unique name (up to you to make sure they are unique, this is an example)
var uniquifyObjectNames = function(req, res, next) {
    for(var key in req.files) {
        req.files[key].s3ObjectName = '' + parseInt(Math.random(100000));
    }
}

// set up the connect-stream-s3 middleware
var s3StreamMiddleware = connectStreamS3({
    accessKeyId     : process.env.ACCESS_KEY_ID,
    secretAccessKey : process.env.SECRET_ACCESS_KEY,
    awsAccountId    : process.env.AWS_ACCOUNT_ID,
    region          : amazon.US_EAST_1,
    bucketName      : 'your-bucket-name',
    concurrency     : 2, // number of concurrent uploads to S3 (default: 3)
});

// create the app and paths
var app = module.exports = express.createServer();

app.use(express.bodyParser());

app.post('/upload', uniquifyObjectNames, s3StreamMiddleware, function(req, res, next) {
    for(var key in req.files) {
        console.log('File "' + key + '" uploaded as : ' + req.files[key].s3ObjectName);
    }
    res.redirect('/thanks');
});
```

# How Does it Work #

<code>connect-stream-s3</code> relies upon <code>express.bodyParser()</code> since it uses the <code>req.files</code>
object. This object already contains pointers to the files on disk and it is these files that are being used when
uploading to Amazon S3.

## Setting the Uploaded ObjectName for your Bucket ##

<code>connect-stream-s3</code> looks for an attribute on each of the req.files objects called <code>s3ObjectName</code>
which you *must* set in some middleware *before* the streaming middleware is called. Therefore the order goes (as the
example above shows):

    express.bodyParser();
    uniquifyObjectNames(); // sets s3ObjectName on each uploaded file
    s3StreamMiddleware();

If you *don't* set s3ObjectName on each uploaded file, <code>connect-stream-s3</code> will complain and call next()
with an error, so make sure you set it to values appropriate to your application.

Note: <code>connect-stream-s3</code> originally used the <code>req.files[field].name</code> field as a default but this
really makes no sense at all and has the side-effect that if someone uploads a file with a filename the same as a
previous one, it would get overwritten. I decided that having this as a default was bad, so you are forced to set
s3ObjectName.

# Reporting Issues, Bugs or Feature Requests #

Let me know how you get on, whether you like it and if you encounter any problems:

* https://github.com/appsattic/connect-stream-s3/issues

# Author #

Written by [Andrew Chilton](http://www.chilts.org/blog/)

Copyright 2012 [AppsAttic](http://www.appsattic.com/)

# License #

MIT. See LICENSE for more details.

(Ends)
