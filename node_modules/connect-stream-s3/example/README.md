# Example to show Single and Multiple File Uploads #

You must install express to be able to run this example. Since connect-stream-s3 uses express but doesn't depend on it,
it is not a requirement of the package, hence you must install it yourself.

From the top-level directory of connect-stream-s3, run the following:

    $ cd example
    $ npm install express
    $ npm install jade

Now set some environment variables (use your own Amazon credentials and bucket name):

    $ export ACCESS_KEY_ID=...
    $ export SECRET_ACCESS_KEY=...
    $ export AWS_ACCOUNT_ID=...
    $ export BUCKET_NAME=...

Now run the app server and upload one or more files. The example demonstrates two different ways to name your S3
ObjectNames but how you do it is entirely dependent on your application:

    $ node app.js

Then browse to http://localhost:3000/ and upload a couple of files and browse to your bucket using:

* https://console.aws.amazon.com/s3/home

(Ends)
