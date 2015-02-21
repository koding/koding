$ = require 'jquery'
FollowButton = require './commonviews/followbutton'


module.exports = class MemberFollowToggleButton extends FollowButton

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

