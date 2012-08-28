require('./harness');
var testName = __filename.replace(__dirname+'/','').replace('.js','');
connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    var callbackCalled = false;
    
    connection.exchange('node.'+testName+'.exchange', {type: 'topic'}, function(exchange) {
        connection.queue( 'node.'+testName+'.queue', { durable: false, autoDelete : true },  function (queue) {
            puts("Queue ready");

            // main test for callback
            queue.bind(exchange, 'node.'+testName+'.topic.bindCallback', function() {
                puts("Single queue bind callback called");
                callbackCalled = true;
            });
            
            // nothing to be asserted / checked with these, other than they don't blow up.
            queue.bind(exchange, 'node.'+testName+'.topic.nullCallback', null);
            queue.bind(exchange, 'node.'+testName+'.topic.undefinedCallback', undefined);
            queue.bind(exchange, 'node.'+testName+'.topic.nonFunctionCallback', "Not a callback");
            
            // Regression test for no callback being supplied not blowing up
            queue.bind(exchange, 'node.'+testName+'.topic.noCallback');
            
            setTimeout(function() {
                assert.ok(callbackCalled, "Callback was not called");
                puts("Single queue bind callback succeeded");
                connection.destroy();},
                2000);
        });
    });
});
  
