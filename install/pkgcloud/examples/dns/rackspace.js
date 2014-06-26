var pkgcloud = require('../../lib/pkgcloud'),
    _		 = require('underscore');

var rackspace = pkgcloud.dns.createClient({
    provider: 'rackspace',
    username: 'rax-user-id',
    apiKey: '1234567890asdbchehe'
  });

// Basic DNS management operations. Please note that due to the asynchronous nature of Javascript programming,
// the code sample below will cause unexpected results if run as-a-whole and are meant for documentation 
// and illustration purposes.

// 1 - Get all DNS "Zones" associates with your account
rackspace.getZones(function (err, zones) {
  if (err) {
    console.dir(err);
    return;
  }

  _.each(zones, function (zone) {
    console.log(zone.id + ' ' + zone.name);
  });

});

// 2 - Create a new "Zone". The details object has these required fields: name, admin email, 
// ttl and comment are optional. *IMPORTANT*: Currently the service will check the domain name you are 
// trying to use is actually registered. If it cannot find a record for it, it will error out.
var details = {
  name: 'example.org',
  email: 'admin@example.org',
  ttl: 300,
  comment: 'I pity .foo'
};

rackspace.createZone(details, function (err, zone) {
  if (err) {
    console.dir(err);
    return;
  }

  console.log(zone.id + ' ' + zone.name + ' ' + zone.ttl);

});

// 3 - Get the "Zone" we just created and get its records

rackspace.getZones({ name: 'example.org' }, function (err, zones) {
  if (err) {
    console.dir(err);
    return;
  }

	if (zones.length) {
    console.log('We have parent Zone');
    rackspace.getRecords(zones[0], function (err, records) {
      if (err) {
        console.dir(err);
        return;
      }

      _.each(records, function (record){
        console.log(record.toJSON());
      });
    });
	}
});

// 4 - Let's add a new DNS A-record to a "Zone". Record has three required fields: type, name, data
var _rec = {
  name: 'sub.example.org',
  type: 'A',
  data: '127.0.0.1'
};

rackspace.getZones({ name: 'example.org' }, function (err, zones) {
  if (err) {
    console.dir(err);
    return;
  }

  if (zones.length) {
    console.log('We have parent Zone');
		rackspace.createRecord(zones[0], _rec, function (err, rec) {
      if (err) {
        console.dir(err);
        return;
      }

      console.log('Record successfully created');
      console.log(rec.name + ' ' + rec.data + ' ' + rec.ttl);

    });
	}
});

// 5 - Now let's remove the "Zone" and all of its children records.
rackspace.getZones({ name: 'example.org' }, function (err, zones) {
  if (err) {
    console.dir(err);
    return;
  }

  if (zones.length) {
    console.log('We have parent Zone');
		rackspace.deleteZone(zones[0], function (err) {
      if (err) {
        console.dir(err);
        return;
      }

      console.log('Zone and records were successfully deleted');

		});
	}
});