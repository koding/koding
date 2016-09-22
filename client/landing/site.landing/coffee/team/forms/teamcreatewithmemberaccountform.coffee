kd                             = require 'kd'
utils                          = require './../../core/utils'
TeamJoinWithInvitedAccountForm = require './teamjoinwithinvitedaccountform'


module.exports = class TeamCreateWithMemberAccountForm extends TeamJoinWithInvitedAccountForm

  constructor: (options = {}, data) ->

    super options, data

    @username.input.setValue utils.getTeamData().profile?.nickname

    @backLink = @getButtonLink 'BACK', '/Team/Domain'


  createButtonLinkPartial: -> "Not you? Create with a <a href='#'>fresh account!</a>"


  pistachio: ->

    """
    {{> @username}}
    {{> @password}}
    {{> @tfcode}}
    {{> @buttonLink}}
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    {{> @backLink}}
    """
