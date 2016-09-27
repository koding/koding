kd                   = require 'kd'
utils                = require './../../core/utils'
JView                = require './../../core/jview'
LoginInputView       = require './../../login/logininputview'
TeamJoinBySignupForm = require './teamjoinbysignupform'


module.exports = class TeamUsernameTabForm extends TeamJoinBySignupForm

  constructor: (options = {}, data) ->

    teamData = utils.getTeamData()

    options.buttonTitle   = 'Done!'
    options.email       or= teamData.signup?.email

    super options, data

    @backLink = @getButtonLink 'BACK', '/Team/Domain'


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
