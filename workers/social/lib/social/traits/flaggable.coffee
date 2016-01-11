module.exports = class Flaggable
  { secure } = require 'bongo'

  mark: secure ({ connection:{ delegate } }, flag, callback = -> ) ->
    role = @constructor.getFlagRole?() ? 'content'
    @flag flag, yes, delegate.getId(), role, callback

  unmark: secure ({ connection:{ delegate } }, flag, callback = -> ) ->
    role = @constructor.getFlagRole() ? 'content'
    @unflag flag, delegate.getId(), role, callback
