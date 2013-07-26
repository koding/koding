class FollowButton extends KDToggleButton

  constructor:(options, data)->
    options.cssClass = @utils.curryCssClass "follow-btn", options.cssClass
    options.title        or= "Follow"
    options.dataPath     or= "followee"
    options.defaultState or= "Follow"
    options.bind           = "mouseenter mouseleave"
    options.loader       or=
      color                : "#333333"
      diameter             : 18
      top                  : 11
    options.states       or= [
      title    : "Follow"
      callback : @createStateCallback "follow"
    ,
      title    : "Following"
      callback : @createStateCallback "unfollow"
    ]
    super

  createStateCallback:(method)->
    (callback)=>
      unless @inProgress
        @inProgress = yes

        setTimeout =>
          @inProgress = no
        , 10000

        @getData()[method] (err, response)=>
          @inProgress = no
          unless err
            callback? null
            @redecorateState()

  decorateState:(name)->

  redecorateState:->
    @setTitle @state.title

    if @state.title is 'Follow'
      @unsetClass 'following-btn'
    else
      @setClass 'following-btn'

    @hideLoader()

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

  decorateState:(name)->
    KD.track "Members", name, @getData().profile.nickname
    super
