kd             = require 'kd'
hljs           = require 'highlight.js'
dateFormat     = require 'dateformat'

curryIn        = require 'app/util/curryIn'
outputParser   = require './outputparser'
objectToString = require 'app/util/objectToString'


module.exports = class OutputView extends kd.ScrollView


  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'output has-markdown' }

    super options, data

    @container = new kd.CustomHTMLView
      tagName  : 'pre'
      cssClass : 'output-view'

    @code = @container.addSubView new kd.CustomHTMLView
      tagName  : 'code'

    @highlight = (@getOption 'highlight') or 'profile'

    @stringifyOptions = {}

    if separator = @getOption 'separator'
      @stringifyOptions = { separator }


  viewAppended: -> @addSubView @container

  raise : -> @setClass   'raise'

  fall  : -> @unsetClass 'raise'

  clear : ->

    @code.updatePartial ''
    return this

  stringify: (content) ->

    for item, i in content
      content[i] = if typeof item is 'object'
      then objectToString item, @stringifyOptions else item

    content = content.join ' '


  add: (content...) ->

    content = @stringify content
    content = "[#{dateFormat Date.now(), 'HH:MM:ss'}] #{content}\n"
    @code.setPartial hljs.highlight(@highlight, content).value
    @scrollToBottom()

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

    content = @stringify content
    @code.updatePartial hljs.highlight(@highlight, content).value
    @scrollToBottom()

    return this


  handleError: (err, prefix = 'An error occurred:') ->
    return no  unless err

    kd.warn '[outputView]', err
    outputParser.showUserFriendlyError err.message

    return @add prefix, err.message or err


  scrollToBottom: ->

    @getDelegate()?.scrollToBottom?()

    super
