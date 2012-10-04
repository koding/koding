var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var SearchService = awssum.load('amazon/cloudsearch').SearchService;

var ss = new SearchService({
    domainName : 'test',
    domainId   : 'cjbekamwcb3coo6y4ulvgiithy',
});

var opts = {
    q : 'ian'
};

ss.Search(opts, function(err, data) {
    fmt.msg("searching for something - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});

var argsWithFields = {
    'q'      : 'searchterm',
    'facet'  : 'size,color,section', // comma separated fields
    'field' : {
        'color' : {
            'constraints' : "'red','green','blue'",
            'sort'        : 'alpha',
            'top-n'       : 10,
        },
        'year' : {
            'constraints' : '2000..2011',
            'sort'        : 'count',
            'top-n'       : 50,
        },
    },
};

ss.Search(argsWithFields, function(err, data) {
    fmt.msg("searching for something - expecting failure (ENOTFOUND ie. no search Domain(Id/Name))");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
