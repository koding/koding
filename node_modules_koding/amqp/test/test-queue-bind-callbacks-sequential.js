require('./harness');
var testName = __filename.replace(__dirname+'/','').replace('.js','');

connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    
    connection.exchange('node.'+testName+'.exchange', {type: 'topic'}, function(exchange) {
        connection.queue( 'node.'+testName+'.queue', { durable: false, autoDelete : true },  function (queue) {
            puts("Queue ready");

            // main test for sequential callback issue
            queue.bind( exchange,  'node.'+testName+'.topic.bindCallback1', function() { 
                puts("bind callback called");
                assert.ok(false, "This callback should not be called unless the sequential bind callback issue has been fixed");}
            );
            queue.bind( exchange,  'node.'+testName+'.topic.bindCallback2', function() { 
                puts("bind callback called");
                assert.ok(false, "This callback should not be called unless the sequential bind callback issue has been fixed");}
            );
            queue.bind( exchange,  'node.'+testName+'.topic.bindCallback2', function() { 
                puts("bind callback called");
                assert.ok(true, "This callback should have be called, as the last of the sequential callbacks");}
            );
            
        });
        
        setTimeout(function() { connection.destroy();}, 2000);
    });
});
  
