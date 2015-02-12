class TopicFollowButton extends KDToggleButton

  constructor : (options = {}, data) ->

    options.cssClass      = @utils.curry "topic-follow-btn", options.cssClass
    options.defaultState  = if data.isParticipant then "Unfollow" else "Follow"
    options.loader        =
      color               : "#7d7d7d"
    options.icon          = yes

    options.states        = [
      title     : "Follow"
      cssClass  : "follow"
      apiMethod : "follow"
      callback  : @bound "toggleFollowingState"
    ,
      title     : "Unfollow"
      cssClass  : "following"
      apiMethod : "unfollow"
      callback  : @bound "toggleFollowingState"

    ]

    super options, data

  click: (event) ->

    KD.utils.stopDOMEvent event

    super


  toggleFollowingState : ->

    KD.requireMembership

      onFailMsg     : "Login required to follow"
      callback      : =>

        {channel}   = KD.singleton "socialapi"
        {apiMethod} = @getState()
        {id}        = @getData()

        @showLoader()

        channel[apiMethod]
          channelId   : id
        , (err, data) =>

          if err
            @hideLoader()

            return false

          @toggleState()

          @setClass @getState().cssClass


  setFollowingState: (isFollowing) ->

    name = if isFollowing then "Unfollow" else "Follow"
    @setState name
    @setClass @getState().cssClass