class AvatarAreaIconLink extends KDCustomHTMLView

  constructor:(options,data)->
    options = $.extend
      tagName     : "a"
      partial     : "<span class='count'><cite></cite><span class='arrow-wrap'><span class='arrow'></span></span></span><span class='icon'></span>"
      attributes  :
        href      : "#"
    ,options
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
    event.preventDefault()
    event.stopPropagation()

    popup = @getDelegate()
    popup.show()