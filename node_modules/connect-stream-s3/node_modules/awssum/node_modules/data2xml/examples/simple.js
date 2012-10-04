var data2xml = require('../data2xml').data2xml;

var empty = {};
console.log(data2xml('TopLevel', empty));
console.log();

var simple = {
    Simple1 : 1,
    Simple2 : 2,
};
console.log(data2xml('TopLevel', simple));
console.log();

var hierarchy = {
    Simple1 : 1,
    Simple2 : {
        Item1 : 'item 1',
        Item2 : 'item 2',
        Item3 : 'item 3',
    },
};
console.log(data2xml('TopLevel', hierarchy));
console.log();

var withAttrs = {
    mine : {
        _attr : {
            color : 'white',
            wheels : 4,
        },
        _value : 'Ford Capri',
    },
    yours : 'Vauxhall Astra',
};
console.log(data2xml('cars', withAttrs));
console.log();

var withArray = {
    MyArray : [
        'Simple Value',
        {
            _attr : { type : 'colour' },
            _value : 'White',
        }
    ],
};
console.log(data2xml('TopLevel', withArray));
console.log();
