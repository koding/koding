class LikeView extends KDView

  constructor:(options={}, data)->

    options.tagName            or= 'span'
    options.cssClass           or= 'like-view'
    options.tooltipPosition    or= 'se'
    options.checkIfLikedBefore  ?= yes

    super options, data

    @_lastUpdatedCount = -1
    @_currentState = no

    @likeCount    = new ActivityLikeCount
      tooltip     :
        gravity   : options.tooltipPosition
        title     : ""
      bind        : "mouseenter"
      mouseenter  : => @fetchLikeInfo()
      attributes  :
        href      : "#"
      click       : (event)=>
        # event.preventDefault()
        if data.meta.likes > 0
          data.fetchLikedByes {},
            sort : timestamp : -1
          , (err, likes) =>
            new FollowedModalView {title:"Members who liked <cite>#{data.body}</cite>"}, likes
      , data

    @likeLink = new ActivityActionLink

    @setTemplate @pistachio()

    if options.checkIfLikedBefore
      data.checkIfLikedBefore (err, likedBefore)=>
        @likeLink.updatePartial if likedBefore then "Unlike" else "Like"
        @_currentState = likedBefore

  fetchLikeInfo:->

    data = @getData()

    return if @_lastUpdatedCount is data.meta.likes
    @likeCount.getTooltip().update title: "Loading..."

    if data.meta.likes is 0
      @likeLink.updatePartial "Like"
      return

    data.fetchLikedByes {},
      limit : 3
      sort  : timestamp : -1
    , (err, likes) =>

      peopleWhoLiked   = []

      if likes

        likes.forEach (item)=>
          if peopleWhoLiked.length < 3
            {firstName, lastName} = item.profile
            peopleWhoLiked.push "<strong>" + firstName + " " + lastName + "</strong>"
          else return

        sep = ', '
        tooltip =
          switch data.meta.likes
            when 0 then ""
            when 1 then "#{peopleWhoLiked[0]}"
            when 2 then "#{peopleWhoLiked[0]} and #{peopleWhoLiked[1]}"
            when 3 then "#{peopleWhoLiked[0]}#{sep}#{peopleWhoLiked[1]} and #{peopleWhoLiked[2]}"
            else "#{peopleWhoLiked[0]}#{sep}#{peopleWhoLiked[1]}#{sep}#{peopleWhoLiked[2]} and <strong>#{data.meta.likes - 3} more.</stron>"

        @likeCount.getTooltip().update { title: tooltip }
        @_lastUpdatedCount = likes.length

  click:(event)->
    event.preventDefault()

    if $(event.target).is("a.action-link")
      @getData().like (err)=>

        KD.showError err,
          AccessDenied : 'Permission denied to like activities'
          KodingError  : 'Something went wrong while like'

        unless err
          @_currentState = not @_currentState
          @likeLink.updatePartial if @_currentState is yes then "Unlike" else "Like"

  pistachio:->
    """{{> @likeLink}}{{> @likeCount}}"""

class LikeViewClean extends LikeView

  constructor:->

    @seperator = new KDCustomHTMLView "span"
    super

    @seperator.updatePartial if @getData().meta.likes then ' · ' else ''

    @likeCount.on "countChanged", (count) =>
      @seperator.updatePartial if count then ' · ' else ''

  pistachio:->
    """<span class='comment-actions'>{{> @likeLink}}{{> @seperator}}{{> @likeCount}}</span>"""

