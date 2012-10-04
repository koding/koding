data2xml is a data to XML converter with a nice interface (for NodeJS).

[![Build Status](https://secure.travis-ci.org/appsattic/node-data2xml.png?branch=master)](http://travis-ci.org/appsattic/node-data2xml)

Installation
------------

The easiest way to get it is via npm:

    npm install data2xml

Info and Links:

* npm info data2xml
* http://search.npmjs.org/#/data2xml
* https://github.com/appsattic/node-data2xml/

Examples
--------

Note: in each example, I am leaving out the XML declaration. I am also pretty printing the output - the package doesn't
do this for you!

    var data2xml = require('data2xml');

    data2xml('TopLevelElement', {
        _attr : { xmlns : 'http://appsattic.com/xml/namespace' }
        SimpleElement : 'A simple element',
        ComplexElement : {
            A : 'Value A',
            B : 'Value B',
        },
    });

    =>

    <TopLevelLement xmlns="http://appsattic.com/xml/namespace">
        <SimpleElement>A simple element</SimpleElement>
        <ComplexElement>
            <A>Value A</A>
            <B>Value B</B>
        </ComplexElement>
    </TopLevelLement>

If you want an element containing data you can do it one of two ways. A simple piece of data will work, but if you want
attributes you need to specify the value in the element object:

    data2xml('TopLevelElement', {
        SimpleData : 'Simple Value',
        ComplexData : {
            _attr : { type : 'colour' },
            _value : 'White',
        }
    });

    =>

    <TopLevelLement xmlns="http://appsattic.com/xml/namespace">
        <SimpleData>Simple Value</SimpleData>
        <ComplexData type="color">White</ComplexData>
    </TopLevelLement>

You can also specify which properties your attributes and values are in (using the same example as above):

    data2xml('TopLevelElement', {
        SimpleData : 'Simple Value',
        ComplexData : {
            '@' : { type : 'colour' },
            '#' : 'White',
        },
        {
            attrProp : '@',
            valProp  : '#',
        }
    });

    =>

    <TopLevelLement xmlns="http://appsattic.com/xml/namespace">
        <SimpleData>Simple Value</SimpleData>
        <ComplexData type="color">White</ComplexData>
    </TopLevelLement>

If you want an array, just put one in there:

    data2xml('TopLevelElement', {
        MyArray : [
            'Simple Value',
            {
                _attr : { type : 'colour' },
                _value : 'White',
            }
        ],
    });

    =>

    <TopLevelLement xmlns="http://appsattic.com/xml/namespace">
        <MyArray>Simple Value</MyArray>
        <MyArray type="color">White</MyArray>
    </TopLevelLement>

Why data2xml
------------

Looking at the XML modules out there I found that the data structure I had to create to get some XML out of the other
end was not very nice, nor very easy to create. This module is designed so that you can take any plain old data
structure in one end and get an XML representation out of the other.

In some cases you need to do something a little special (rather than a lot special) but these are for slightly more
tricky XML representations.

Also, I wanted a really simple way to convert data structures in NodeJS into an XML representation for the Amazon Web
Services within node-awssum. This seemed to be the nicest way to do it (after trying the other js to xml modules).

What data2xml does
------------------

data2xml converts data structures into XML. It's that simple. No need to worry!

What data2xml doesn't do
------------------------

Data2Xml is designed to be an easy way to get from a data structure to XML. Various other JavaScript to XML modules try
and do everything which means that the interface is pretty dire. If you just want an easy way to get XML using a sane
data structure, then this module is for you.

To decide this, you need to know what this module doesn't do. It doesn't deal with:

* mixed type elements (such as `<markup>Hello <strongly>World</strongly></markup>`)
* pretty formatting - after all, you're probably sending this XML to another machine
* CDATA elements ... though I probably _should_ add this (somehow)
* data objects which are (or have) functions
* ordered elements - if you pass me an object, it's members will be output in an order defined by 'for m in object'
* comments
* processing instructions
* entity references
* all the other stuff you don't care about when dealing with data

(Ends)
