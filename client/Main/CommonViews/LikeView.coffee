class LikeView extends JView

  constructor:(options={}, data)->

    options.tagName            or= 'span'
    options.cssClass           or= 'like-view'
    options.tooltipPosition    or= 'se'
    options.checkIfLikedBefore  ?= no
    options.useTitle            ?= yes

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
      click       : (event) =>
        KD.utils.stopDOMEvent event
        if data.meta.likes > 0
          data.fetchLikedByes {},
            sort : timestamp : -1
          , (err, likes) =>
            new ShowMoreDataModalView {title:"Members who liked <cite>#{@utils.expandTokens data.body, data}</cite>"}, likes
      , data

    @likeLink = new ActivityActionLink partial: "Like"

    # We need to getridoff this asap FIXME ~HK
    if options.checkIfLikedBefore? and KD.isLoggedIn()
      data.checkIfLikedBefore? (err, likedBefore)=>
        {useTitle} = @getOptions()
        if likedBefore
          @setClass "liked"
          @likeLink.updatePartial "Unlike" if useTitle
        else
          @unsetClass "liked"
          @likeLink.updatePartial "Like" if useTitle

        @_currentState = likedBefore

  fetchLikeInfo:->

    data = @getData()

    return if @_lastUpdatedCount is data.meta.likes
    @likeCount.getTooltip().update title: "Loading..."


    if data.meta.likes is 0
      @unsetClass "liked"
      return

    data.fetchLikedByes {},
      limit : 3
      sort  : timestamp : -1
    , (err, likes) =>

      users  = []
      likers = []
      guests = 0

      if likes

        strong  = (x)-> "<strong>#{x}</strong>"

        for item in likes
          name = KD.utils.getFullnameFromAccount item
          likers.push "#{strong name}"

          if item.type is 'unregistered' then guests++
          else users.push "#{strong name}"

        if data.meta.likes > 3
          sep = ', '
          andMore = "and <strong>#{data.meta.likes - 3} more.</strong>"
        else
          sep = ' and '
          andMore = ""

        # For following cases tooltip will be:
        #
        # 1 guest  : a guest
        # 2 guests : 2 guests
        # 3 guests : 3 guests
        #
        # 1 user   : user[0]
        # 2 users  : user[0] and username[1]
        # 3 users  : user[0], user[1] and user[2]
        #
        # 1 guest 1 users : a guest and user[0]
        # 1 guest 2 users : a guest, user[0], and user[1] {and N-3 more}
        # 2 guests 1 user : user[0] and 2 guests {and N-3 more}
        #
        # N users/guest   : user[0], user[1], user[2] and N-3 more
        # N guests        : 3 guests and N-3 more

        tooltip =
          switch data.meta.likes
            when 0 then ""
            when 1 then "#{likers[0]}"
            when 2
              if guests is 2 then "#{strong '2 guests'}"
              else "#{likers[0]} and #{likers[1]}"
            else
              switch guests
                when 3 then "#{strong '3 guests'} #{andMore}"
                when 2 then "#{users[0]}#{sep}#{strong '2 guests'} #{andMore}"
                else "#{likers[0]}, #{likers[1]}#{sep}#{likers[2]} #{andMore}"

        @likeCount.getTooltip().update { title: tooltip }
        @_lastUpdatedCount = data.meta.likes

  click:(event)->
    event.preventDefault()

    if $(event.target).is("a.action-link")
      @getData().like (err)=>
        KD.showError err,
          AccessDenied : 'You are not allowed to like activities'
          KodingError  : 'Something went wrong while like'

        unless err
          @_currentState = not @_currentState
          {useTitle} = @getOptions()
          if @_currentState
            @setClass "liked"
            @likeLink.updatePartial "Unlike" if useTitle
            KD.mixpanel "Activity like, success"
            KD.getSingleton("badgeController").checkBadge
              source : "JNewStatusUpdate" , property : "likes", relType : "like", targetSelf : 1
          else
            @unsetClass "liked"
            @likeLink.updatePartial "Like" if useTitle
            KD.mixpanel "Activity unlike, success"

          @_lastUpdatedCount = -1

  pistachio:->
    """{{> @likeLink}}{{> @likeCount}}"""

class LikeViewClean extends LikeView

  constructor:->
    super
    @likeLink.updatePartial "Like"

  pistachio:->
    """<span class='comment-actions'>{{> @likeLink}}{{> @likeCount}}</span>"""
