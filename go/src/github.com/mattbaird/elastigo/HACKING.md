
Testing
-----------------

To run tests, this library loads data into an elasticsearch server and tests against that.

See api/coretest_test.go.   The data set should remain the same as it pulls a known set of github archive data.

usage:

  $cd core

    $go test -v -host eshost -loaddata # load the data

    $go test -v -host eshost # without load data, which only needs to run once

Clean out the Elasticsearch index:

    http -v DELETE http://localhost:9200/github
    or
    curl -XDELETE http://localhost:9200/github
