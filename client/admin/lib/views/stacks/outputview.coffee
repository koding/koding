kd             = require 'kd'

hljs           = require 'highlight.js'
JView          = require 'app/jview'
curryIn        = require 'app/util/curryIn'
dateFormat     = require 'dateformat'


module.exports = class OutputView extends kd.ScrollView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'output has-markdown'

    super options, data

    @container = new kd.CustomHTMLView
      tagName  : 'pre'
      cssClass : 'output-view'

    @code = @container.addSubView new kd.CustomHTMLView
      tagName  : 'code'

    @highlight = (@getOption 'highlight') or 'profile'


  raise : -> @setClass   'raise'
  fall  : -> @unsetClass 'raise'

  clear : ->

    @code.updatePartial ''
    return this


  add: (content...) ->

    content = content.join ' '
    content = "[#{dateFormat Date.now(), 'HH:MM:ss'}] #{content}\n"
    @code.setPartial hljs.highlight(@highlight, content).value
    @scrollToBottom()

    return this


  set: (content...) ->

    content = content.join ' '
    @code.updatePartial hljs.highlight(@highlight, content).value
    @scrollToBottom()

    return this


  handleError: (err) ->
    return no  unless err

    kd.warn '[outputView]', err
    @add 'An error occured:', err.message or err


  pistachio: ->
    """{{> @container}}"""