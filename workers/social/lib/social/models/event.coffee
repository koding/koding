{ Module }  = require 'jraphical'
KodingError = require '../error'


module.exports = class JEvent extends Module

  @set

    sharedEvents :
      static     : []
      instance   : []

    schema       :

      requester  :
        type     : Object

      group      :
        type     : String

      event      :
        message  : String
        details  : Object

      createdAt  :
        type     : Date
        default  : -> new Date

      type       :
        type     : String
        enum     : ['Wrong type specified!', [
                    'log', 'error', 'warning'
                   ]]
        default  : -> 'log'


  humanize = (stack) ->

    # we don't need first two lines
    stack = stack.split '\n'
    stack.splice 1, 2
    stack = stack.join '\n'

    # remove cwd path from stack
    stack = stack.replace ///#{process.cwd()}\////g, ''

    return stack


  create = (type, content, callback) ->

    group     = undefined
    requester = undefined

    if typeof content is 'string'
      message = content
    else if typeof content is 'object'
      { message, details, group, requester, trace } = content

    unless message
      return JEvent.warning
        message : 'message is required'
        trace   : yes

    callback           ?= JEvent.error
    createdAt           = new Date

    trace              ?= no
    details            ?= {}
    details.trace      ?= humanize (new Error).stack  if trace

    event               = { message, details }
    eventData           = { type, event, createdAt }

    eventData.group     = group      if group?
    eventData.requester = requester  if requester?

    (new JEvent eventData).save callback


  @log     = (arg, cb) -> create 'log',     arg, cb
  @error   = (arg, cb) -> create 'error',   arg, cb
  @warning = (arg, cb) -> create 'warning', arg, cb
