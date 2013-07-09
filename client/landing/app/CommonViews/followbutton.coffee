class FollowButton extends KDToggleButton

  constructor:(options = {}, data)->

    options.cssClass = @utils.curryCssClass "follow-btn", options.cssClass
    options = $.extend
      defaultState : if data.followee then "Unfollow" else "Follow"
      dataPath     : "followee"
      loader       :
        color      : "#333333"
        diameter   : 18
        top        : 11
      states       : [
        title      : "Follow"
        cssClass   : options.stateOptions?.follow?.cssClass
        callback   : (cb)=>
          @getData().follow (err, response)=>
            KD.showError err, options.errorMessages
            @getData().followee = response
            cb? err
      ,
        title      : "Unfollow"
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
        @setState "Unfollow"  if following

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
