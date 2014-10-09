class AvatarAreaIconLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.tagName  = 'a'
    options.cssClass = KD.utils.curry 'acc-icon', options.cssClass

    super options,data

    @count = 0


  updateCount: (newCount = 0) ->

    @$('.count cite').text newCount
    @count = newCount

    if newCount is 0
    then @$('.count').addClass "hidden"
    else @$('.count').removeClass "hidden"

  click: do ->

    clickedInside = no

    return (event) ->

      KD.utils.stopDOMEvent event

      return clickedInside = no  if clickedInside

      { windowController } = KD.singletons
      popup                = @getDelegate()

      if popup.hasClass "active"
        popup.hide()
        windowController.removeLayer popup
      else
        @setClass 'active'
        popup.show()
        windowController.addLayer popup
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



