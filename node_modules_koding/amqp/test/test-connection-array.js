var harness = require('./harness');

// Test that connection handles an array of hostnames.
// If given one, without an index (`this.hosti`), it will randomly pick one.
options.host = [options.host,"nohost"];
options.reconnect = true;


for (var i = 0; i < options.host.length; i++){
  test();
}

function test() {
  var conn = harness.createConnection();

  var callbackCalled = false;
  conn.once('ready', function() {
    callbackCalled = true;
    conn.destroy();
  });

  conn.once('close', function() {
    assert(callbackCalled);
    callbackCalled = false;
  });

  conn.once('error', function(e) {
    // If we get an error, it should be ENOTFOUND (bad dns);
    assert(e.code === 'ENOTFOUND');
    callbackCalled = true;
  });
}

