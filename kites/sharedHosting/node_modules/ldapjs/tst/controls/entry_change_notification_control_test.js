
var test = require('tap').test;

var asn1 = require('asn1');

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var getControl;
var EntryChangeNotificationControl;



///--- Tests


test('load library', function(t) {
  EntryChangeNotificationControl =
    require('../../lib').EntryChangeNotificationControl;
  t.ok(EntryChangeNotificationControl);
  getControl = require('../../lib').getControl;
  t.ok(getControl);
  t.end();
});


test('new no args', function(t) {
  t.ok(new EntryChangeNotificationControl());
  t.end();
});


test('new with args', function(t) {
  var c = new EntryChangeNotificationControl({
    type: '2.16.840.1.113730.3.4.7',
    criticality: true,
    value: {
      changeType: 8,
      previousDN: 'cn=foobarbazcar',
      changeNumber: 123456789
    }
  });
  t.ok(c);
  t.equal(c.type, '2.16.840.1.113730.3.4.7');
  t.ok(c.criticality);
  t.equal(c.value.changeType, 8);
  t.equal(c.value.previousDN, 'cn=foobarbazcar');
  t.equal(c.value.changeNumber, 123456789);


  var writer = new BerWriter();
  c.toBer(writer);
  var reader = new BerReader(writer.buffer);
  var psc = getControl(reader);
  t.ok(psc);
  console.log('psc', psc.value);
  t.equal(psc.type, '2.16.840.1.113730.3.4.7');
  t.ok(psc.criticality);
  t.equal(psc.value.changeType, 8);
  t.equal(psc.value.previousDN, 'cn=foobarbazcar');
  t.equal(psc.value.changeNumber, 123456789);

  t.end();
});

test('tober', function(t) {
  var psc = new EntryChangeNotificationControl({
    type: '2.16.840.1.113730.3.4.7',
    criticality: true,
    value: {
      changeType: 8,
      previousDN: 'cn=foobarbazcar',
      changeNumber: 123456789
    }
  });

  var ber = new BerWriter();
  psc.toBer(ber);

  var c = getControl(new BerReader(ber.buffer));
  t.ok(c);
  t.equal(c.type, '2.16.840.1.113730.3.4.7');
  t.ok(c.criticality);
  t.equal(c.value.changeType, 8);
  t.equal(c.value.previousDN, 'cn=foobarbazcar');
  t.equal(c.value.changeNumber, 123456789);

  t.end();
});
