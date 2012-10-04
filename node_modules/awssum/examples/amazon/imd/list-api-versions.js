var fmt = require('fmt');
var awssum = require('awssum');
var Imd = awssum.load('amazon/imd').Imd;

var imd = new Imd();

imd.ListApiVersions(function(err, data) {
    fmt.msg("getting metadata - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
