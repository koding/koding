kd                   = require 'kd'
utils                = require './../../core/utils'

LoginInputView       = require './../../login/logininputview'
TeamJoinBySignupForm = require './teamjoinbysignupform'


module.exports = class TeamUsernameTabForm extends TeamJoinBySignupForm

  constructor: (options = {}, data) ->

    teamData = utils.getTeamData()

    options.buttonTitle   = 'Create Your Team'
    options.email       or= teamData.signup?.email

    super options, data

    backRoute = if kd.config.environment is 'default'
    then '/Team/Domain'
    else '/Team/Payment'

    @backLink = @getButtonLink 'BACK', backRoute


  pistachio: ->

    """
    {{> @email}}
    {{> @username}}
    {{> @password}}
    {{> @passwordStrength}}
    {{> @buttonLink}}
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    {{> @backLink}}
    """
