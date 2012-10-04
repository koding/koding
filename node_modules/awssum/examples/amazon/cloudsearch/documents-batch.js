var fmt = require('fmt');
var awssum = require('awssum');
var amazon = awssum.load('amazon/amazon');
var DocumentService = awssum.load('amazon/cloudsearch').DocumentService;

var ds = new DocumentService({
    domainName : 'test',
    domainId   : 'cjbekamwcb3coo6y4ulvgiithy',
});

var opts = {
    Docs : [
        {
            "type": "add",
            "id": "tt0484562",
            "version": 1337648735,
            "lang": "en",
            "fields": {
                "title": "The Seeker: The Dark Is Rising",
                "director": "Cunningham, David L.",
                "genre": ["Adventure","Drama","Fantasy","Thriller"],
                "actor": ["McShane, Ian","Eccleston, Christopher","Conroy, Frances"]
            }
        },
        { "type": "delete",
          "id": "tt0434409",
          "version": 1337648735
        },
    ],
};

ds.DocumentsBatch(opts, function(err, data) {
    fmt.msg("putting some documents - expecting success");
    fmt.dump(err, 'Error');
    fmt.dump(data, 'Data');
});
