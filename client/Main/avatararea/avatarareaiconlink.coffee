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
    KD.utils.stopDOMEvent event

    delegate = @getDelegate()
    if delegate.hasClass "active"
      @delegate.hide()
    else
      @delegate.show()
      @once 'ReceivedClickElsewhere', => @delegate.hide()
