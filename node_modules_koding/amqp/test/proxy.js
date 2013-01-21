// Stolen from Devendra Tewari
// (http://delog.wordpress.com/2011/04/08/a-simple-tcp-proxy-in-node-js/)

var net = require('net');

process.on("uncaughtException", function(e) {
  console.log(e);
});

module.exports.route = function (proxyPort, servicePort, serviceHost) {
  var proxyRoute = this;
  proxyRoute.proxyPort = proxyPort || 9001;
  var servicePort = servicePort || 5672;
  var serviceHost = serviceHost || '127.0.0.1';
  
  proxyRoute.operational = true;
  proxyRoute.serviceSockets = [];
  proxyRoute.proxySockets = [];
  
  proxyRoute.server = net.createServer(function (proxySocket) {
    // If we're "experiencing trouble", immediately end the connection.
    if (!proxyRoute.operational) {
      proxySocket.end();
      return;
    }
    
    // If we're operating normally, accept the connection and begin proxying traffic.
    proxyRoute.proxySockets.push(proxySocket);
    
    var connected = false;
    var buffers = [];
    var serviceSocket = new net.Socket();
    proxyRoute.serviceSockets.push(serviceSocket);
    serviceSocket.connect(parseInt(servicePort), serviceHost);
    serviceSocket.on('connect', function() {
      connected = true;
      for (var i in buffers) {
        serviceSocket.write(buffers[i]);
      }
      buffers = [];
    });
    proxySocket.on('error', function (e) {
      serviceSocket.end();
    });
    serviceSocket.on('error', function (e) {
      console.log('Could not connect to service at host ' + serviceHost + ', port ' + servicePort);
      proxySocket.end();
    });
    proxySocket.on("data", function (data) {
      if (proxyRoute.operational) {
        if (connected) {
          serviceSocket.write(data);
        } else {
          buffers.push(data);
        }
      }
    });
    serviceSocket.on("data", function(data) {
      if (proxyRoute.operational) {
        proxySocket.write(data);
      }
    });
    proxySocket.on("close", function(had_error) {
      serviceSocket.end();
    });
    serviceSocket.on("close", function(had_error) {
      proxySocket.end();
    });
  });
  proxyRoute.listen();
};
module.exports.route.prototype.listen = function () {
  var proxyRoute = this;
  proxyRoute.operational = true;
  proxyRoute.server.listen(proxyRoute.proxyPort);
};
module.exports.route.prototype.close = function () {
  var proxyRoute = this;
  proxyRoute.operational = false;
  for (var index in proxyRoute.serviceSockets) {
    proxyRoute.serviceSockets[index].destroy();
  }
  proxyRoute.serviceSockets = [];
  for (var index in proxyRoute.proxySockets) {
    proxyRoute.proxySockets[index].destroy();
  }
  proxyRoute.proxySockets = [];
  proxyRoute.server.close();
};
module.exports.route.prototype.interrupt = function (howLong) {
  var proxyRoute = this;
  console.log('interrupting proxy connection...');
  proxyRoute.close();
  setTimeout(function () {
    proxyRoute.listen();
  }, howLong || 50);
};

if (!module.parent) {
  var proxyPort = process.argv[2];
  var servicePort = process.argv[3];
  var serviceHost = process.argv[4];
  var proxyRoute = new module.exports.route(proxyPort, servicePort, serviceHost);
  // Don't exit until parent kills us.
  setInterval(function () {
    if (process.argv[5]) {
      proxyRoute.interrupt();
    }
  }, parseInt(process.argv[5]) || 1000);
}