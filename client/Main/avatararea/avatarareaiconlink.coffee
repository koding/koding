class AvatarAreaIconLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.tagName  = 'a'
    options.cssClass = KD.utils.curry 'acc-icon', options.cssClass

    super options,data

    @count = 0

    @getDelegate().on 'AvatarPopupShouldBeHidden', =>

      @unsetClass 'active'


  updateCount: (newCount = 0) ->

    @$('.count cite').text newCount
    @count = newCount

    if newCount is 0
    then @$('.count').addClass "hidden"
    else @$('.count').removeClass "hidden"

  click: (event) ->

    KD.utils.stopDOMEvent event

    return clickedInside = no  if clickedInside

    popup = @getDelegate()

    if popup.hasClass "active"
      popup.hide()
    else
      @setClass 'active'
      popup.show()
      popup.once "ReceivedClickElsewhere", (event) =>
        clickedInside = @isInside event.target
        @unsetClass 'active'
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



