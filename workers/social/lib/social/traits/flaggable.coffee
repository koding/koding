module.exports = class Flaggable
  {secure} = require 'bongo'
  
  @getFlagRole =-> 'content'
  
  mark: secure ({connection:{delegate}}, flag, callback)->
    @flag flag, yes, delegate.getId(), @constructor.getFlagRole(), callback
    
  unmark: secure ({connection:{delegate}}, flag, callback)->
    @unflag flag, delegate.getId(), @constructor.getFlagRole(), callback