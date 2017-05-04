debug = (require 'debug') 'nse:controller:stack'

kd = require 'kd'
Events = require '../events'
BaseController = require './base'


module.exports = class StackController extends BaseController


  check: (callback) ->

    stackTemplate = @getData()
    debug 'generating stack', stackTemplate

    cc    = kd.singletons.computeController
    stack = cc.findStackFromTemplateId stackTemplate._id

    callback if stack then {
      name    : 'Internal'
      message : '
        There is a stack generated from this template,
        do you want to reinitialize ?
      '
      action  :
        title : 'Reinitialize'
        fn    : =>
          @emit Events.Action, Events.HideWarning
          kd.singletons.computeController.reinitStack stack
    } else null


  save: (callback) -> @check (err) =>

    return callback err  if err

    stackTemplate = @getData()
    debug 'generating stack', stackTemplate

    @emit Events.WarnUser, {
      message : 'Generating stack...'
      loader  : yes
    }

    stackTemplate.generateStack { verify: yes }, (err, stack) =>
      return callback err  if err

      @emit Events.WarnUser, {
        message  : 'Stack generated successfully!'
        autohide : 1500
      }

      callback err, stack
