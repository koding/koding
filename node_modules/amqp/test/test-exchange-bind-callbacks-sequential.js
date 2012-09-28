require('./harness');
var testName = __filename.replace(__dirname+'/','').replace('.js','');

connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    var callbacksCalled = 0;
    
    connection.exchange('node.'+testName+'.source', {type: 'topic'}, function (sourceExchange) {
        connection.exchange( 'node.'+testName+'.destination', { durable: false, autoDelete : true },  function (destinationExchange) {
            puts("Destination exchange ready");

            // main test for sequential callback issue
            destinationExchange.bind( sourceExchange, 'node.'+testName+'.topic.bindCallback1', function() { 
                puts("bind callback called");
                assert.ok(false, "This callback should not be called unless the sequential bind callback issue has been fixed");}
            );
            destinationExchange.bind( sourceExchange, 'node.'+testName+'.topic.bindCallback2', function() { 
                puts("bind callback called");
                assert.ok(false, "This callback should not be called unless the sequential bind callback issue has been fixed");}
            );
            destinationExchange.bind( sourceExchange, 'node.'+testName+'.topic.bindCallback2', function() { 
                puts("bind callback called");
                assert.ok(true, "This callback should have be called, as the last of the sequential callbacks");}
            );
            
        });
        
        setTimeout(function() { connection.destroy();}, 2000);
    });
});