require('./harness');
var testName = __filename.replace(__dirname+'/','').replace('.js','');

connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    var callbacksCalled = 0;
    
    connection.exchange('node.'+testName+'.source', {type: 'topic'}, function (sourceExchange) {
        connection.exchange( 'node.'+testName+'.destination', { durable: false, autoDelete : true },  function (destinationExchange) {
            puts("Destination exchange ready");

            // main test for callback
            destinationExchange.bind(sourceExchange, 'node.'+testName+'.topic.bindCallback', function() {
                puts("Single destination exchange bind callback called");
                callbackCalled = true;
            });
            
            // nothing to be asserted / checked with these, other than they don't blow up.
            destinationExchange.bind(sourceExchange, 'node.'+testName+'.topic.nullCallback', null);
            destinationExchange.bind(sourceExchange, 'node.'+testName+'.topic.undefinedCallback', undefined);
            destinationExchange.bind(sourceExchange, 'node.'+testName+'.topic.nonFunctionCallback', "Not a callback");
            
            // Regression test for no callback being supplied not blowing up
            destinationExchange.bind(sourceExchange, 'node.'+testName+'.topic.noCallback');
            
            setTimeout(function() {
                assert.ok(callbackCalled, "Callback was not called");
                puts("Single queue bind callback succeeded");
                connection.destroy();},
                2000);
        });
    });
});