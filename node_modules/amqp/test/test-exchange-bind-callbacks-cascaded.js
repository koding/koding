require('./harness');
var testName = __filename.replace(__dirname+'/','').replace('.js','');

connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    var callbacksCalled = 0;
    
    connection.exchange('node.'+testName+'.source', {type: 'topic'}, function (sourceExchange) {
        connection.exchange( 'node.'+testName+'.destination', { durable: false, autoDelete : true },  function (destinationExchange) {
            puts("Destination exchange ready");

            // main test for callback
            destinationExchange.bind(sourceExchange, 'node.'+testName+'.topic.bindCallback.outer', function (destExchange) {
                puts("First exchange bind callback called");
                callbacksCalled++;
                destExchange.bind(sourceExchange, 'node.'+testName+'.topic.bindCallback.inner', function() {
                    puts("Second exchange bind callback called");
                    callbacksCalled++;
                });
            });
            
            setTimeout(function() {
                assert.ok(callbacksCalled == 2, "Callback was not called");
                puts("Cascaded exchange bind callback succeeded");
                connection.destroy();},
                2000);
        });
    });
});
  
