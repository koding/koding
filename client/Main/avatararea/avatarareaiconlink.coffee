class AvatarAreaIconLink extends KDCustomHTMLView

  constructor:(options,data)->
    options = $.extend
      tagName     : "a"
      partial     : """
        <span class='count'>
          <cite></cite>
        </span>
        <span class='icon'></span>
      """
      attributes  :
        href      : "#"
    , options

    super options,data
    @count = 0

  updateCount:(newCount = 0)->
    @$('.count cite').text newCount
    @count = newCount

    if newCount is 0
      @$('.count').removeClass "in"
    else
      @$('.count').addClass "in"

  click:(event)->
    windowController = KD.singleton "windowController"
    KD.utils.stopDOMEvent event

    groupSwitcherPopup = @getDelegate()
    if groupSwitcherPopup.hasClass "active"
      groupSwitcherPopup.hide()
      windowController.removeLayer groupSwitcherPopup
    else
      groupSwitcherPopup.show()
      windowController.addLayer groupSwitcherPopup
      groupSwitcherPopup.once "ReceivedClickElsewhere", =>
        groupSwitcherPopup.hide()
