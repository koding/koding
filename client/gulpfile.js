var fs = require('fs');
var child_process = require('child_process');
var debug = require('debug')('client:scripts');
var gulp = require('gulp');
var build = require('bant-build');
var through = require('through2');
var coffeeify = require('coffeeify');
var rewritify = require('rewritify');
var pistachioify = require('pistachioify');
var browserify = require('browserify');
var watchify = require('watchify');
var glob = require('glob');
var xtend = require('xtend');
var gitrev = require('git-rev');
var mkdirp = require('mkdirp');
var path = require('path');
var pretty = require('pretty-bytes');


var modules = glob.sync('*/bant.json').map(function (row) {
  var id = row.split('/')[0];
  return id;
});

var opts = {
  outdir: path.resolve(__dirname, '../website/a/p/p'),
  baseurl: '/a/p/p',
  modules: modules,
  rev: null,
  browserify: {
    extensions: ['.coffee', '.js', '.json'],
    // debug: true
  },
  globals: {
    config: {},
    appClasses: {},
    navItems: [],
    navItemIndex: [],
    REMOTE_API: {}
  }
};


require('coffee-script/register');
require('./gulpfile.coffee')(opts);


gulp.task('create-dirs', function (cb) {
  mkdirp(opts.outdir + '/thirdparty', function (err) {
    if (err) throw err;
    cb();
  });
});

gulp.task('set-remote-api', function (cb) {
  child_process.exec('node get-bongo-schema.js', function (err, res) {
    if (err) debug('could not get bongo-schema');
    opts.globals.REMOTE_API = xtend(opts.globals.REMOTE_API, JSON.parse(res));
    cb();
  });
});

gulp.task('set-config-apps', ['set-revid'], function (cb) {
  var apps = {};
  modules.forEach(function (id) {
    var name; 
    if (id == 'ide') name = 'IDE';
    else {
      name = id.charAt(0).toUpperCase() + id.slice(1);
    }
    var obj = {
      identifier: id,
      name: name,
      style: opts.baseurl + '/' + id + '.css?v=' + opts.rev,
      script: opts.baseurl + '/' + id + '.js?v=' + opts.rev
    };
    apps[name] = obj;
  });
  opts.globals.config = xtend(opts.globals.config, { apps: apps });
  cb();
});

gulp.task('set-revid', function (cb) {
  gitrev.short(function (res) {
    opts.rev = res;
    cb();
  });
});

gulp.task('copy-thirdparty', ['create-dirs'], function (cb) {
  var i = 0;
  glob('thirdparty/**/*', {nodir: true}, function (err, res) {
    i = res.length-1;
    if (err) throw err;
    res.forEach(function (file, j) {
      if (file === 'thirdparty/Readme.md') return;
      mkdirp(opts.outdir + '/' + file.split('/').slice(0, -1).join('/'), function (err) {
        if (err) throw err;
        fs.createReadStream(__dirname + '/' + file).pipe(fs.createWriteStream(opts.outdir + '/' + file));
        if (!(i-j)) cb();
      });
    });
  });
});

gulp.task('scripts',
  [
    'set-remote-api',
    'set-config-apps',
    'copy-thirdparty'
  ],

  function (cb) {

    debug('modules: ' + modules.join(', '));
    debug('outdir: ' + opts.outdir);
    debug('rev: ' + opts.rev);

    var mapping = {};

    modules.forEach(function (name) {
      mapping[name] = '../' + name + '/lib';
    });

    //opts.globals.modules = modules;

    b = watchify(browserify(xtend(opts.browserify, watchify.args)))
      .transform(coffeeify, { global: true })
      .transform(pistachioify, { global: true })
      .transform(rewritify, {
        global: true,
        extensions: ['coffee'],
        basedir: __dirname,
        mapping: mapping
      });

    bant = build(b, {
      globals: opts.globals
    }).on('bundle', function (bundle) {
      var outfile = path.join(opts.outdir, bundle.name + '.js');
      fs.writeFile(outfile, bundle.source, function (err, res) {
        if (err) debug('could not write ' + outfile);
        debug(pretty(bundle.source.length) + ' written to ' + path.basename(outfile));
      });
    });

    gulp.src(['*/bant.json']).pipe(bant);
  }
);

gulp.task('default', ['styles', 'scripts'], function (cb) {
  mkdirp(opts.outdir + '/thirdparty', function (err) {
    if (err) throw err;
    cb();
  });
});
