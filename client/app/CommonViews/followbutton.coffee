class FollowButton extends KDToggleButton

  constructor:(options = {}, data)->

    options.cssClass = @utils.curry "follow-btn", options.cssClass
    options = $.extend
      defaultState : if data.followee then "Following" else "Follow"
      bind         : 'mouseenter mouseleave'
      dataPath     : "followee"
      loader       :
        color      : "#333333"
      states       : [
        title      : "Follow"
        cssClass   : options.stateOptions?.follow?.cssClass
        callback   : (cb)=>
          KD.requireMembership
            tryAgain  : yes
            onFailMsg : "Login required to follow"
            onFail    : => cb yes
            callback  : =>
              account = @getData()
              account.follow (err, response) ->
                account.followee = response
                cb? err
      ,
        title      : "Following"
        cssClass   : options.stateOptions?.unfollow?.cssClass
        callback   : (cb)=>
          @getData().unfollow (err, response)=>
            KD.showError err, options.errorMessages
            @getData().followee = response
            cb? err
      ]

    , options

    super options, data

  viewAppended:->
    super

    unless @getData().followee
      {dataType} = @getOptions()
      return  unless dataType

      KD.whoami().isFollowing? @getData().getId(), dataType, \
      (err, following) =>
        @getData().followee = following
        @setState "Following", no  if following

  mouseEnter:->
    if @getTitle() is "Following"
      @setTitle "Unfollow"

  mouseLeave:->
    if @getTitle() is "Unfollow"
      @setTitle "Following"

class MemberFollowToggleButton extends FollowButton

  constructor:(options = {}, data)->

    options = $.extend

      errorMessages  :
        KodingError  : 'Something went wrong while follow'
        AccessDenied : 'You are not allowed to follow members'
      stateOptions   :
        unfollow     :
          cssClass   : 'following-btn'
      dataType       : 'JAccount'

    , options

    super options, data

  decorateState:(name, userEvent)->
    super
