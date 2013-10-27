require('./harness').run();
var testName = __filename.replace(__dirname+'/','').replace('.js','');
var msgsReceived = 0;

connection.addListener('ready', function () {
    puts("connected to " + connection.serverProperties.product);
    
    connection.exchange('node.'+testName+'.dstExchange', {type: 'headers'}, function(dstExchange) {
        connection.exchange('node.'+testName+'.srcExchange', {type: 'headers'}, function(srcExchange) {
            dstExchange.bind_headers(srcExchange, {test: 'validHeaderKey'}, function () {
                connection.queue( 'node.'+testName+'.nestedExchangeQueue', { durable: false, autoDelete : true },  function (queue) {
                    queue.bind(dstExchange, '#', function () {
                        queue.subscribe(function ( msg ) {
                            puts(msg.data.toString());
                            msgsReceived++;
                        });
                        srcExchange.publish('node.'+testName+'.nestedExchangeTest', 
                            'valid Message',
                            {
                                headers: {test: 'validHeaderKey'}
                            }
                        );
                        srcExchange.publish('node.'+testName+'.nestedExchangeTest',
                            'wrong Message',
                            {
                                headers: {test: 'wrongKey'}
                            }
                        );

                        setTimeout(function () {
                          // wait one second to receive the message, then quit
                          queue.destroy();
                          dstExchange.destroy();
                          srcExchange.destroy();
                          connection.end();
                        }, 1000);
                    });
                });
            });
        });
    });
});

process.addListener('exit', function() {
  assert.equal(1, msgsReceived);
});
