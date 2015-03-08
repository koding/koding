var bant = require('bant');
var fs = require('fs');
var path = require('path');
var xtend = require('xtend');
var coffeeify = require('coffeeify');
var pistachioify = require('pistachioify');
var uglifyify = require('uglifyify');
var inspect = require('util').inspect;
var pretty = require('pretty-bytes');

require('coffee-script/register');
var defaults = require('./globals.coffee');

var apps = [
  'about',
  'account',
  'ace',
  'activity',
  'app',
  'dashboard',
  'environments',
  'features',
  'feeder',
  'finder',
  'ide',
  'kites',
  'legal',
  'members',
  'pricing',
  'terminal',
  'viewer',
];

var rewriteMap = apps.reduce(function (acc, x) {
  acc[x] = './' + x + '/lib/';
  return acc;
}, {});

var manifests = apps.map(function (x) {
  return __dirname + '/' + x + '/bant.json'
});

var opts = {
  basedir: __dirname,
  debug: false,
  extensions: [ '.coffee' ],
  transform: [ coffeeify, pistachioify ],
  rewriteMap: rewriteMap,
  factor: false,
  globals: xtend(defaults, { 
    REMOTE_API: require('./bongo-schema.json'),
    modules: apps.map(function (x) {
      var manifest = __dirname + '/' + x + '/bant.json';
      manifest = require(require.resolve(manifest));
      var name;
      if (x === 'ide') {
        name = 'IDE';
      } else {
        name = x.charAt(0).toUpperCase() + x.slice(1);
      }

      return {
        identifier: x,
        name: name,
        routes: manifest.routes,
        style: '/a/p/p/' + x + '.css?v=' + 666
      };
    })
  })
};

var b = bant.watch(opts);
b.use(manifests);
//b.transform(uglifyify, { global: true });
//
b._bpack.hasExports = true;

var outfile = path.resolve(__dirname, '../website/a/p/p/app.js');

function bundle () {
  var start = Date.now();
  b.bundle(function (err, src) {
    if (err) {
      console.log(inspect(err));
      //throw err; // watch mode'da degilse
    } else {
      fs.writeFile(outfile, src, function (err, res) {
        if (err) throw err;
        var secs = ((Date.now() - start)/1000).toFixed(2);
        console.log(pretty(src.length) + ' written to ' + outfile + ' (' + secs + ')');
      });
    }
  });
}

bundle();
b.on('update', function (ids) {
  console.log('updated ', ids);
  bundle();
});
