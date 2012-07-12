# querystring.node.js

This node module provides robust querystring parsing and stringifying. It is based heavily
on the [YUI QueryString module located here](http://github.com/isaacs/yui3/tree/master/src/querystring/js).

## Acknowledgements

Thanks to Isaac Schlueter for pointing me to the YUI code and allowing me to tweak it for node.js.

## querystring.js

Exports the __parse__ and __stringify__ methods from the __querystring-parse__ 
and __querystring-stringify__ sub-modules, repsectively.

### parse example

    var sys = require("sys");
    var qs = require("./querystring");

    var str = qs.parse("foo=bar&baz=qux");
    sys.puts(JSON.stringify(str)); // => {"foo":"bar","baz":"qux"}

    str = qs.parse("foo[bar][][bla]=baz");
    sys.puts(JSON.stringify(str)); // => {"foo":{"bar":[{"bla":"baz"}]}}



### stringify example

    var sys = require("sys");
    var qs = require("./querystring");

    var obj = {"foo":"bar","baz":"qux"};
    sys.puts(qs.stringify(obj)); // => foo=bar&baz=qux

    obj = {"foo":{"bar":[{"bla":"baz"}]}};
    sys.puts(qs.stringify(obj)); // => foo%5Bbar%5D%5B%5D%5Bbla%5D=baz


## querystring-parse.js

Provides a __parse__ function which takes a string and returns a javascript object


## querystring-stringify.js

Provides a __stringify__ function which takes a javascript object and returns a query string

## Other

See test.js for a few more examples.
