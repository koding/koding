kd                  = require 'kd'
KDCustomHTMLView    = kd.CustomHTMLView
JView               = require '../jview'


module.exports = class AvatarAreaIconLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.tagName  = 'a'
    options.cssClass = kd.utils.curry 'acc-icon', options.cssClass

    super options,data

    @count = 0


  updateCount: (newCount = 0) ->

    @$('.count cite').text newCount
    @count = newCount

    if newCount is 0
    then @$('.count').addClass "hidden"
    else @$('.count').removeClass "hidden"

  click: do (skipNextClick = no, listItemClicked = no) -> (event) ->

    kd.utils.stopDOMEvent event

    return skipNextClick = no  if skipNextClick

    popup = @getDelegate()
    popup.show()

    popup.once 'NotificationListItemClicked', (event) =>
      listItemClicked = yes

    popup.once 'ReceivedClickElsewhere', (event) =>
      skipNextClick = if listItemClicked then no else @isInside event.target
      listItemClicked = no
      popup.hide()



  isInside: (target) ->

    itself = @$()[0]
    count  = @$('.count')[0]
    cite   = @$('cite')[0]
    icon   = @$('.icon')[0]

    target in [itself, count, cite, icon]


  pistachio: ->
    """
    <span class='count hidden'>
      <cite></cite>
    </span>
    <span class='icon'></span>
    """





