function executeDifferentLogCalls(logger){
    logger.log('log');
    logger.info('info');
    logger.warn('warn');
    logger.error('error');
    logger.debug('debug');
}

function runTests(){
    var Syslog = require('../index.js');
    var logger = new Syslog({port : 5514});

    executeDifferentLogCalls(logger);

    logger.setMessageComposer(function(message, severity){
        return new Buffer('<' + (this.facility * 8 + severity) + '>' +
                this.getDate() + ' ' + '[' + process.pid + ']:' + message);
    });
    executeDifferentLogCalls(logger);

    setTimeout(function(){
        process.exit();
    }, 500);

}


function setupServer(){
    var dgram = require("dgram");

    var server = dgram.createSocket("udp4");
    var messages = [];


    server.on("message", function (msg, rinfo) {
      console.log(msg.toString());
      messages.push(msg.toString());
    });

    server.on("listening", function () {
      var address = server.address();
      console.log("server listening " +
          address.address + ":" + address.port);
      runTests();
    });

    server.bind(5514);
}

setupServer();

