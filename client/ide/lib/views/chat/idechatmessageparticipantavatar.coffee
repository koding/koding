kd = require 'kd'
AvatarView = require 'app/commonviews/avatarviews/avatarview'

###*
 * The purpose of this class is to prevent users
 * going to Profile pages when clicked. Instead of doing anything
 * It's gonna emit an event to its delegator when it's clicked.
 *
 * @class IDEChatMessageParticipantAvatar
 * @extends AvatarView
###
module.exports = class IDEChatMessageParticipantAvatar extends AvatarView

  click: (event) ->

    return  unless participant = @getOption 'origin'

    kd.utils.stopDOMEvent event

    @emit 'ParticipantSelected', participant


