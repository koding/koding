kd    = require 'kd'

strip = require 'app/util/stripHTMLtoText'

module.exports = class BannerNotificationView extends kd.CustomHTMLView



  constructor:(options = {}, data) ->

    options.cssClass         = kd.utils.curry 'system-notification', options.cssClass
    options.container      or= kd.singletons.mainView.panelWrapper
    options.hideCloseButton ?= no
    options.onClose         ?= kd.noop

    super options, data

    @bindTransitionEnd()

    @title = new kd.CustomHTMLView
      tagName : 'b'
      partial : @getOption 'title'

    @content = new kd.CustomHTMLView
      tagName : 'span'
      partial : @getOption 'content'

    { onClose, hideCloseButton } = @getOptions()
    @close = new kd.CustomHTMLView
      tagName    : 'a'
      attributes : { href : '#' }
      cssClass   : 'close'
      click      : (event) =>
        kd.utils.stopDOMEvent event
        @hide()
        onClose()
    @close.hide()  if hideCloseButton

    @once 'viewAppended', => kd.utils.defer @bound 'show'

    { closeTimer, container } = @getOptions()
    container.addSubView this

    return  unless closeTimer
    return  unless typeof closeTimer is 'number'

    kd.utils.wait closeTimer, @bound 'hide'


  show: -> @setClass 'in'


  hide: ->

    @once 'transitionend', @bound 'destroy'
    @unsetClass 'in'


  pistachio: -> "<p title='#{@getOption 'title'} #{strip @getOption 'content'}'>{{> @title}} {{> @content}}</p>{{> @close}}"
