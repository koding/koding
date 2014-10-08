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


  click: (event) ->

    KD.utils.stopDOMEvent event

    { windowController } = KD.singletons
    popup                = @getDelegate()

    if popup.hasClass "active"
      popup.hide()
      windowController.removeLayer popup
    else
      popup.show()
      windowController.addLayer popup
      popup.once "ReceivedClickElsewhere", => popup.hide()


  pistachio: ->
    """
    <span class='count'>
      <cite></cite>
    </span>
    <span class='icon'></span>
    """


