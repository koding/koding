kd = require 'kd'

BaseController = require './base'
dateFormat     = require 'dateformat'
objectToString = require 'app/util/objectToString'


module.exports = class LogsController extends BaseController


  stringify = (content) ->

    for item, i in content
      content[i] = if typeof item is 'object'
      then objectToString item else item

    return content.join ' '


  add: (content...) ->

    content = stringify content
    content = "[#{dateFormat Date.now(), 'HH:MM:ss'}] #{content}"
    @editor.addContent content

    return this


  clear: ->

    @editor.setContent ''
    return this


  addAndWarn: (content) ->

    @add content

    modal = new kd.ModalView
      title          : ''
      cssClass       : 'stack-modal'
      content        : content
      overlay        : yes
      overlayOptions :
        cssClass     : 'second-overlay'
        overlayClick : yes
      buttons        :
        close        :
          title      : 'Close'
          cssClass   : 'solid medium gray'
          callback   : -> modal.destroy()

    return this


  set: (content...) ->

    @clear()
    @add content...

    return this


  handleError: (err, prefix = 'An error occurred:') ->

    return no  unless err
    # outputParser.showUserFriendlyError err.message
    return @add prefix, err.message or err
