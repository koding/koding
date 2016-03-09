kd                  = require 'kd.js'
utils               = require './../../core/utils'
LoginViewInlineForm = require './../../login/loginviewinlineform'
LoginInputView      = require './../../login/logininputview'
TeamJoinByLoginForm = require './teamjoinbyloginform'


module.exports = class TeamLoginAndCreateTabForm extends TeamJoinByLoginForm

  constructor: (options = {}, data)->

    options.cssClass      = 'clearfix login-form'
    options.buttonTitle or= "Done!"

    super options, data

    @backLink = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link back'
      partial  : '<i></i> <a href="/Team/Domain">Back</a>'


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
    {{> @backLink}}
    {{> @button}}
    """
