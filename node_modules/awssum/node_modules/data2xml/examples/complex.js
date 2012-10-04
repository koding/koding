var data2xml = require('../data2xml').data2xml;

var data = {
    _attr : {
        xmlns : 'https://route53.amazonaws.com/doc/2011-05-05/',
        random : 'Quick test for \' and \"',
    },
    ChangeBatch : {
        Comment : 'This is a comment (with dodgy characters like < & > \' and ")',
        Changes : {
            Change : [
                {
                    Action : 'CREATE',
                    ResourceRecordSet : {
                        Name : 'www.example.com',
                        Type : 'A',
                        TTL : 300,
                        ResourceRecords : {
                            ResourceRecord : [
                                {
                                    Value : '192.0.2.1'
                                }
                            ]
                        }
                    },
                },
                {
                    Action : 'DELETE',
                    ResourceRecordSet : {
                        Name : 'foo.example.com',
                        Type : 'A',
                        TTL : 600,
                        ResourceRecords : {
                            ResourceRecord : [
                                {
                                    Value : '192.0.2.3'
                                }
                            ]
                        }
                    },
                },
                {
                    Action : 'CREATE',
                    ResourceRecordSet : {
                        Name : 'foo.example.com',
                        Type : 'A',
                        TTL : 600,
                        ResourceRecords : {
                            ResourceRecord : [
                                {
                                    Value : '192.0.2.1'
                                }
                            ]
                        }
                    },
                },
            ],
        },
    },
};

console.log(data2xml('ChangeResourceRecordSetsRequest', data));
console.log();

console.log(
    data2xml('TopLevelElement', {
        MyArray : [
            'Simple Value',
            {
                _attr : { type : 'colour' },
                _value : 'White',
            }
        ],
    })
);
console.log();
