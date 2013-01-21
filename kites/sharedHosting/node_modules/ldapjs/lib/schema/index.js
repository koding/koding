// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var createAddHandler = require('./add_handler');
var createModifyHandler = require('./mod_handler');
var createSearchHandler = require('./search_handler');
var parser = require('./parser');



///--- API

module.exports = {

  createAddHandler: createAddHandler,

  createModifyHandler: createModifyHandler,

  createSearchHandler: createSearchHandler,

  load: parser.load

};
