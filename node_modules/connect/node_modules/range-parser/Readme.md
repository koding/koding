
# node-range-parser

  Range header field parser.

## Example:

```js
parse(1000, 'bytes=0-499').should.eql([{ start: 0, end: 499 }]);
parse(1000, 'bytes=40-80').should.eql([{ start: 40, end: 80 }]);
parse(1000, 'bytes=-500').should.eql([{ start: 500, end: 999 }]);
parse(1000, 'bytes=-400').should.eql([{ start: 600, end: 999 }]);
parse(1000, 'bytes=500-').should.eql([{ start: 500, end: 999 }]);
parse(1000, 'bytes=400-').should.eql([{ start: 400, end: 999 }]);
parse(1000, 'bytes=0-0').should.eql([{ start: 0, end: 0 }]);
parse(1000, 'bytes=-1').should.eql([{ start: 999, end: 999 }]);
```

## Installation

```
$ npm install range-parser
```