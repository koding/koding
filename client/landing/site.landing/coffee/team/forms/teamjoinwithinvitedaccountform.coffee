kd              = require 'kd'
utils           = require './../../core/utils'
LoginInputView  = require './../../login/logininputview'
TeamJoinTabForm = require './../forms/teamjointabform'


module.exports = class TeamJoinWithInvitedAccountForm extends TeamJoinTabForm

  constructor: (options = {}, data) ->

    teamData = utils.getTeamData()

    options.buttonTitle or= "Join #{kd.config.groupName}!"
    options.email       or= teamData.signup.username

    super options, data

    teamData = utils.getTeamData()

    @username = new LoginInputView
      cssClass        : 'hidden'
      inputOptions    :
        label         : 'Your Username'
        placeholder   : 'Pick a username'
        name          : 'username'
        defaultValue  : @getOption 'email'

    @password   = @getPassword()
    @tfcode     = @getTFCode()
    @button     = @getButton @getOption 'buttonTitle'
    @buttonLink = @getButtonLink @createButtonLinkPartial(), null, (event) =>
      kd.utils.stopDOMEvent event
      return  unless event.target.tagName is 'A'

      @emit 'FormNeedsToBeChanged', no, no

    @on 'FormValidationFailed', @button.bound 'hideLoader'
    @on 'FormSubmitFailed', @button.bound 'hideLoader'


  createButtonLinkPartial: -> "Not you? <a href='#'>Join with a fresh account!</a>"

  submit: (formData) ->

    teamData = utils.getTeamData()
    teamData.signup ?= {}
    teamData.signup.alreadyMember = yes

    super formData


  pistachio: ->

    """
    {{> @username}}
    {{> @password}}
    {{> @tfcode}}
    {{> @buttonLink}}
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    """
