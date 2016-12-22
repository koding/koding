kd                  = require 'kd'
utils               = require './../../core/utils'
LoginViewInlineForm = require './../../login/loginviewinlineform'
LoginInputView      = require './../../login/logininputview'
TeamJoinByLoginForm = require './teamjoinbyloginform'


module.exports = class TeamLoginAndCreateTabForm extends TeamJoinByLoginForm

  constructor: (options = {}, data) ->

    options.cssClass      = 'clearfix login-form'
    options.buttonTitle or= 'Create Your Team'

    super options, data

    backRoute = if kd.config.environment is 'default'
    then '/Team/Domain'
    else '/Team/Payment'

    @backLink = @getButtonLink 'BACK', backRoute


  createButtonLinkPartial: ->

    teamData = utils.getTeamData()
    if teamData.profile
      { firstName, nickname, hash } = teamData.profile
      name = "#{firstName or '@'+nickname}"
      "Are you <img src='#{utils.getGravatarUrl 24, hash}'/> <a href='#'>#{name}</a>?"
    else
      "Want to start with a <a href='#'>fresh account</a>?"


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
