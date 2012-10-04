# RELEASE PROCEDURE #

    $ npm test
    $ make jshint

    $ vi package.json # change the version number

    RELEASE=0.11.0

    git commit -m "Bump version number to v$RELEASE" package.json RELEASE.md
    git push origin master

Create the tag:

    git tag v$RELEASE
    git push origin v$RELEASE

Start the branch (if this is the start of a vx.y.0 series):

    git branch vx.y
    git push origin vx.y

Then, in a /tmp/ directory:

    cd /tmp/
    rm -rf node-awssum
    git clone ~/appsattic/node-awssum/
    cd node-awssum
    npm publish
    cd ~/appsattic/node-awssum/

Once that has been published, look for the tweet to retweet on:

* https://twitter.com/#!/nodenpm

Then finally, change the topic on #awssum on Freenode:

    /topic AwsSum v0.11.0 (latest) | https://awssum.io/ | Please use https://gist.github.com/ to paste

... and update http://awssum.io/ ...

    _config.yml
    changelog.html

(Ends)
