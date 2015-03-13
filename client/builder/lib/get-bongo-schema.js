#!/usr/bin/env node

var path = require('path');
require('coffee-script/register');

var root = path.resolve(__dirname, '../../../');
var config = path.resolve(__dirname, '../../../config/main.dev.coffee');
var models = path.resolve(__dirname, '../../../workers/social/lib/social/models');

process.chdir(root);
config = require(config)().JSON;
process.chdir(process.cwd());
process.env.KONFIG_JSON = config;

new (require('bongo'))({
  root: root,
  models: './' + path.relative(root, models)
}).on('apiReady', function () {
  this.describeApi(function (res) {
    process.stdout.write(JSON.stringify(res) + '\n');
  });
});

