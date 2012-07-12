var sys = require('sys');
var expat = require('./lib/node-expat');
var Buffer = require('buffer').Buffer;
var vows = require('vows');
var assert = require('assert');

function collapseTexts(evs) {
    var r = [];
    var t = "";
    evs.forEach(function(ev) {
	if (ev[0] == 'text')
	    t += ev[1];
	else {
	    if (t != "")
		r.push(['text', t]);
	    t = "";
	    r.push(ev);
	}
    });
    if (t != "")
	r.push(['text', t]);
    return r;
}

function expect(s, evs_expected) {
    for(var step = s.length; step > 0; step--) {
	var evs_received = [];
	var p = new expat.Parser("UTF-8");
	//p.setEncoding("UTF-8");
	p.addListener('startElement', function(name, attrs) {
	    evs_received.push(['startElement', name, attrs]);
	});
	p.addListener('endElement', function(name) {
	    evs_received.push(['endElement', name]);
	});
	p.addListener('text', function(s) {
	    evs_received.push(['text', s]);
	});
	p.addListener('processingInstruction', function(target, data) {
	    evs_received.push(['processingInstruction', target, data]);
	});
	p.addListener('comment', function(s) {
	    evs_received.push(['comment', s]);
	});
	p.addListener('xmlDecl', function(version, encoding, standalone) {
	    evs_received.push(['xmlDecl', version, encoding, standalone]);
	});
	p.addListener('startCdata', function() {
	    evs_received.push(['startCdata']);
	});
	p.addListener('endCdata', function() {
	    evs_received.push(['endCdata']);
	});
	p.addListener('entityDecl', function(entityName, isParameterEntity, value, base, systemId, publicId, notationName) {
	    evs_received.push(['entityDecl', entityName, isParameterEntity, value, base, systemId, publicId, notationName]);
	});
	for(var l = 0; l < s.length; l += step)
	{
	    var end = l + step;
	    if (end > s.length)
		end = s.length;

	    if (!p.parse(s.slice(l, end), false))
		evs_received.push(['error']);
	}

	var expected = JSON.stringify(evs_expected);
	var received = JSON.stringify(collapseTexts(evs_received));
	assert.equal(received, expected);
    }
}

vows.describe('node-expat').addBatch({
    'single element': {
	'simple': function() {
	    expect("<r/>",
		[['startElement', 'r', {}],
		['endElement', 'r']]);
	},
	'single element with attribute': function() {
	    expect("<r foo='bar'/>",
		[['startElement', 'r', {foo: 'bar'}],
		['endElement', 'r']]);
	},
	'single elemeht with differently quoted attributes': function() {
	    expect("<r foo='bar' baz=\"quux\" test=\"tset\"/>",
		[['startElement', 'r', {foo: 'bar', baz: 'quux', test: 'tset'}],
		['endElement', 'r']]);
	},
	'single element with namespaces': function() {
	    expect("<r xmlns='http://localhost/' xmlns:x=\"http://example.com/\"></r>",
		[['startElement', 'r', {xmlns: 'http://localhost/', 'xmlns:x': 'http://example.com/'}],
		['endElement', 'r']]);
	},
	'single element with text content': function() {
	    expect("<r>foo</r>",
		[['startElement', 'r', {}],
		['text', "foo"],
		['endElement', 'r']]);
	},
	'single element with text content and line break': function() {
	    expect("<r>foo\nbar</r>",
		[['startElement', 'r', {}],
		['text', "foo\nbar"],
		['endElement', 'r']]);
	},
	'single element with CDATA content': function() {
	    expect("<r><![CDATA[<greeting>Hello, world!</greeting>]]></r>",
		[['startElement', 'r', {}],
		['startCdata'],
		['text', "<greeting>Hello, world!</greeting>"],
		['endCdata'],
		['endElement', 'r']]);
	},
	'single element with entity text': function() {
	    expect("<r>foo&amp;bar</r>",
		[['startElement', 'r', {}],
		['text', "foo&bar"],
		['endElement', 'r']]);
	},
	'single element with umlaut text': function() {
	    expect("<r>ß</r>",
		[['startElement', 'r', {}],
		['text', "ß"],
		['endElement', 'r']]);
	},
	'from buffer': function() {
	    expect(new Buffer('<foo>bar</foo>'),
		[['startElement', 'foo', {}],
		['text', 'bar'],
		['endElement', 'foo']]);
	}
    },
    'entity declaration': {
	'a billion laughs': function() {
	    expect('<!DOCTYPE b [<!ELEMENT b (#PCDATA)>' +
		   '<!ENTITY l0 "ha"><!ENTITY l1 "&l0;&l0;"><!ENTITY l2 "&l1;&l1;">' +
		   ']><b>&l2;</b>',
		   [["entityDecl","l0",false,"ha",null,null,null,null],
		   ["entityDecl","l1",false,"&l0;&l0;",null,null,null,null],
		   ["entityDecl","l2",false,"&l1;&l1;",null,null,null,null],
		   ["startElement","b",{}],["text","hahahaha"],["endElement","b"]]);
	}
    },
    'processing instruction': {
	'with parameters': function() {
	    expect("<?i like xml?>",
		[['processingInstruction', 'i', 'like xml']]);
	},
	'simple': function() {
	    expect("<?dragons?>",
		[['processingInstruction', 'dragons', '']]);
	},
	'XML declaration with encoding': function() {
	    expect("<?xml version='1.0' encoding='UTF-8'?>",
		[['xmlDecl', '1.0', 'UTF-8', true]]);
	},
	'XML declaration': function() {
	    expect("<?xml version='1.0'?>",
		[['xmlDecl', '1.0', null, true]]);
	}
    },
    'comment': {
	'simple': function() {
	    expect("<!-- no comment -->",
		[['comment', ' no comment ']]);
	}
    },
    'error': {
	'tag name starting with ampersand': function() {
	    expect("<&", [['error']]);
	}
    },
    'stop and resume': {
	topic: function() {
	    var cb = this.callback;
	    var p = new expat.Parser("UTF-8");

	    var input = '\
		<wrap> \
			<short /> \
			<short></short> \
			<long /> \
			<short /> \
			<long>foo</long> \
		</wrap>';

	    var expected = ['wrap', 'short', 'short', 'long', 'short', 'long'];
	    var received = [];

	    var tolerance = 10/100;
	    var expectedRuntime = 1000;
	    var start = new Date();

	    p.addListener('startElement', function(name, attrs) {
		received.push(name);

		// suspend parser for 1/2 second
		if(name == 'long') {
		    p.stop();

		    setTimeout(function() {
			p.resume();
		    }, 500);
		}
	    });

	    p.addListener('endElement', function(name) {
		// finished parsing
		if(name == 'wrap') {
		    // test elements received (count. naming, order)
		    assert.equal(JSON.stringify(received), JSON.stringify(expected));

		    // test timing (+-5%)
		    var now = new Date();
		    var diff = now.getTime() - start.getTime();
		    var max = expectedRuntime + expectedRuntime * tolerance,
			min = expectedRuntime - expectedRuntime * tolerance;

		    assert.ok(diff < max, 'Runtime within maximum expected time');
		    assert.ok(diff > min, 'Runtime at least minimum expected time');

		    return cb(true);
		}
	    });

	    assert.ok(p.parse(input));
	},
	'should have worked': function() {
	    assert.ok(true, 'start & stop works');
	}
    },
    'corner cases': {
	'parse empty string': function() {
	    var p = new expat.Parser("UTF-8");
	    p.parse('');
	    assert.ok(true, "Did not segfault");
	}, 
 	
	'parsing twice the same document with the same parser instance should be fine': 'reset() not yet implemented'
	/*function() {
	   var p = new expat.Parser("UTF-8");
           var xml = "<foo>bar</foo>";
           var result = p.parse(xml);
           assert.ok(result);
           assert.isNull(p.getError());

           var result2 = p.parse(xml);
           assert.isNull(p.getError());
           assert.ok(result2);
            
        }*/
    }
}).run();
