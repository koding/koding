var fmt = require('fmt');
var awssum = require('awssum');
var Imd = awssum.load('amazon/imd').Imd;

var imd = new Imd();

imd.Get(function(err, data) {
    fmt.msg("getting metadata - expecting failure (no Category given)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

imd.Get({}, function(err, data) {
    fmt.msg("getting metadata - expecting failure (no Category given)");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

imd.Get({ Version : 'latest', Category : '/' }, function(err, data) {
    fmt.msg("getting metadata - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

imd.Get({ Version : 'latest', Category : '/meta-data/' }, function(err, data) {
    fmt.msg("getting metadata - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
