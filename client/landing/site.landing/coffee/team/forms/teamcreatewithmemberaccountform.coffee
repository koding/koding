kd                             = require 'kd'
utils                          = require './../../core/utils'
TeamJoinWithInvitedAccountForm = require './teamjoinwithinvitedaccountform'


module.exports = class TeamCreateWithMemberAccountForm extends TeamJoinWithInvitedAccountForm

  constructor: (options = {}, data) ->

    options.buttonTitle = 'Create Your Team'

    super options, data

    @username.input.setValue utils.getTeamData().profile?.nickname

    backRoute = if kd.config.environment is 'default'
    then '/Team/Domain'
    else '/Team/Payment'

    @backLink = @getButtonLink 'BACK', backRoute


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
