kd                  = require 'kd'
KDCustomHTMLView    = kd.CustomHTMLView
JView               = require '../jview'


module.exports = class AvatarAreaIconLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.tagName  = 'a'
    options.cssClass = kd.utils.curry 'acc-icon', options.cssClass

    super options, data

    @count = 0


  updateCount: (newCount = 0) ->

    @$('.count cite').text newCount
    @count = newCount

    if newCount is 0
    then @$('.count').addClass 'hidden'
    else @$('.count').removeClass 'hidden'


  pistachio: ->
    """
    <span class='count hidden'>
      <cite></cite>
    </span>
    <span class='icon'></span>
    """
