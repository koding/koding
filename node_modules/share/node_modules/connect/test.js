var connect = require('./');
var app = connect();

function delay(ms) {
  return function(req, res, next){
    setTimeout(next, ms);
  }
}

// app.use(connect.responseTime());
app.use(connect.logger('dev'));
// app.use(connect.bodyParser());
// app.use(connect.methodOverride());
app.use(connect.cookieParser('test'));
// app.use(connect.session());

// app.use(connect.responseTime());
// app.use(connect.logger('dev'));
// app.use(connect.cookieParser('secret'));
// app.use(connect.bodyParser(), connect.session());
// app.use(connect.methodOverride());

// app.use(delay(1000));
// app.use(delay(1000));
// app.use(delay(1000), delay(1000));

app.use(function(req, res){
  res.setHeader('Content-Length', '5');
  res.end('Hello');
});

app.listen(3000);

// 8500 without
// 8300 with
// 6100 with cookie 7500 without signed check