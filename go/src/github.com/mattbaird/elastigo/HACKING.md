
Testing
-----------------

To run tests, this library loads data into an elasticsearch server and tests against that.

See core/test_test.go.   The data set should remain the same as it pulls a known set of github archive data.

usage:

	$cd core
	
    $go test -v -host eshost -loaddata # load the data
    
    $go test -v -host   # without load data, which only needs to run once

Clean out the Elasticsearch index:
    
    http -v DELETE http://localhost:9200/github