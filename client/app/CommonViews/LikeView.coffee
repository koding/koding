class LikeView extends KDView

  constructor:(options={}, data)->

    options.tagName            or= 'span'
    options.cssClass           or= 'like-view'
    options.tooltipPosition    or= 'se'
    options.checkIfLikedBefore  ?= no

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
        if data.meta.likes > 0
          data.fetchLikedByes {},
            sort : timestamp : -1
          , (err, likes) =>
            new ShowMoreDataModalView {title:"Members who liked <cite>#{data.body}</cite>"}, likes
      , data

    @likeLink = new ActivityActionLink

    @setTemplate @pistachio()

    # We need to getridoff this asap FIXME ~HK
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

      peopleWhoLiked = []
      guestsWhoLiked = 0

      if likes

        for item in likes
          if item.type is 'unregistered'
            guestsWhoLiked++
          else
            name = KD.utils.getFullnameFromAccount item
            peopleWhoLiked.push "<strong>#{name}</strong>"

        sep  = ', '
        and_ = if peopleWhoLiked.length>0 then 'and ' else ''

        guestLikes =
          switch guestsWhoLiked
            when 0 then ""
            when 1 then "#{and_}<strong>a guest</strong>"
            when 2 then "#{and_}<strong>2 guests</strong>"
            when 3 then "<strong>3 guests</strong>"

        tooltip =
          switch peopleWhoLiked.length
            when 0 then "#{guestLikes}"
            when 1 then "#{peopleWhoLiked[0]} #{guestLikes}"
            when 2 then "#{peopleWhoLiked[0]} and #{peopleWhoLiked[1]} #{guestLikes}"
            else "#{peopleWhoLiked[0]}#{sep}#{peopleWhoLiked[1]}#{sep}#{peopleWhoLiked[2]} and <strong>#{data.meta.likes - 3} more.</strong>"

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

