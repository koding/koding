require('./harness').run();
var testName = __filename.replace(__dirname+'/','').replace('.js','');

connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    var callbacksCalled = 0;
    
    connection.exchange('node.'+testName+'.exchange', {type: 'topic'}, function(exchange) {
        connection.queue( 'node.'+testName+'.queue', { durable: false, autoDelete : true },  function (queue) {
            puts("Queue ready");

            // main test for callback
            queue.bind(exchange, 'node.'+testName+'.topic.bindCallback.outer', function(q) {
                puts("First queue bind callback called");
                callbacksCalled++;
                q.bind(exchange, 'node.'+testName+'.topic.bindCallback.inner', function() {
                    puts("Second queue bind callback called");
                    callbacksCalled++;
                });
            });
            
            setTimeout(function() {
                assert.ok(callbacksCalled == 2, "Callback was not called");
                puts("Cascaded queue bind callback succeeded");
                queue.destroy();
                connection.destroy();
            },2000);
        });
    });
});
  
