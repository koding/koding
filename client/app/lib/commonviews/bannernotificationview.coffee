kd    = require 'kd'
JView = require 'app/jview'

module.exports = class BannerNotificationView extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor:(options = {}, data) ->

    options.cssClass    = kd.utils.curry 'system-notification', options.cssClass
    options.container or= kd.singletons.mainView.panelWrapper

    super options, data

    @bindTransitionEnd()

    @title = new kd.CustomHTMLView
      tagName : 'b'
      partial : @getOption 'title'

    @content = new kd.CustomHTMLView
      tagName : 'span'
      partial : @getOption 'content'

    @close = new kd.CustomHTMLView
      tagName    : 'a'
      attributes : href : '#'
      cssClass   : 'close'
      click      : (event) =>
        kd.utils.stopDOMEvent event
        @hide()

    { closeTimer, container } = @getOptions()

    @once 'viewAppended', => kd.utils.defer @bound 'show'

    container.addSubView this

    return  unless closeTimer
    return  unless typeof closeTimer is 'number'

    kd.utils.wait closeTimer, @bound 'hide'



  show: -> @setClass 'in'

  hide: ->

    @once 'transitionend', @bound 'destroy'
    @unsetClass 'in'

  pistachio: -> "<p>{{> @title}} {{> @content}}</p>{{> @close}}"
