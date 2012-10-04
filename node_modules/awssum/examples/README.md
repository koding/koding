# Example Programs

## Running these Programs

Make a copy of the set-env.sh file and fill in the different vars for the
services you want to try and set them in your environment:

    $ cp set-env.sh set-env-me.sh
    $ vi set-env-me.sh
    ...
    $ . set-env-me.sh

Then to run a program, run it from this directory as follows:

    $ node amazon/s3/list-buckets.js

You should see a few lines of information, then 3 lines containing some text, a
dump of the err variable and a dump of the returned data. In some example
programs there are more than request and the returned data will be printed in
random order (the order in which the response comes back, and not the order in
which the requests are sent).

## Program Names

All example programs are named with the form:

    <company>/<service>/<operation>.js

For example:

    amazon/sqs/send-message.js

Each and every program is a standalone example of just one operation on that
service. This also means that some redundant code is at the top of each program
which could have been put into a library, but I decided not to do this since I
wanted each example to be standalone and self-contained.

## OAuth ##

When dealing with an OAuth service, the examples force you to set 5 environment variables. For example, if a service
called ACME used OAuth, you'd need to set the following:

    export ACME_CONSUMER_KEY=blahblah
    export ACME_CONSUMER_SECRET=herpderp
    export ACME_TOKEN=
    export ACME_TOKEN_SECRET=
    export ACME_VERIFIER=

Note that the ACME_TOKEN, ACME_TOKEN_SECRET and the ACME_VERIFIER are not yet filled in.

To fill the first two in, issue a RequestToken against ACME then set the environment variables. Once that is done, the
user needs to use the ACME_TOKEN to authorise your app and in return they'll get a VERIFIER. Set that and then issue a
GetRequest. Finally, you'll get another ACME_TOKEN and ACME_TOKEN_SECRET which override the previous values (they were
temporary credentials, these are your access credentials).

Once you have done all of that, you can now issue authentivated requests against a users private data (for which you
have authorisation).

## A Warning!!!

    DON'T RUN THESE PROGRAMS BLINDLY.

In most cases, you'll be fine, but I can't guarantee that.

So a warning ... in general you should _not_ run these programs directly, since
they _may_ be destructive in your own environment. Also note that I am not
guaranteeing them to work in your environment either. They are just _example_
programs which you can learn from.

On the other hand ... if you _want_ to run them directly, read on ...

I (chilts) can run all of these programs without modification, since with
things like S3, I own the buckets that are being created (bucket names are
unique within that region across all users). You may have to change the bucket
names in these programs to make them work correctly with your account.

On the other hand, with other services such as SQS, you can have a queue name
which is the same as me, therefore you _should_ be able to run all of these
programs without modification. However, I'm not guaranteeing this and in
reality these programs are just examples (do you get the idea yet?). :)

## To Run them Yourself

To run them yourself, take a look in the set-env.sh file and set the
environment variables to be your own credentials. In a production system I
wouldn't recommend using env vars, but for these example programs it makes it
nice and easy. (As a hint, you should probably have a config file with your
credentials in it which can be read by your programs, but presumably not be
able to be written to.)

(Ends)
