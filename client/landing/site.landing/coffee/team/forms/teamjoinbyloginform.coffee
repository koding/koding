kd              = require 'kd'
utils           = require './../../core/utils'
TeamJoinTabForm = require './../forms/teamjointabform'
LoginInputView  = require './../../login/logininputview'


module.exports = class TeamJoinByLoginForm extends TeamJoinTabForm

  constructor: (options = {}, data) ->

    options.buttonTitle or= "Join #{kd.config.groupName}!"

    super options, data

    @username = new LoginInputView
      inputOptions    :
        label         : 'Username or Email'
        placeholder   : 'Enter your koding username or email'
        name          : 'username'
        validate      :
          rules       : { required: yes }
          messages    : { required: 'Please enter your username.' }


    teamData = utils.getTeamData()
    if teamData.profile
      callback = (event) =>
        kd.utils.stopDOMEvent event
        return  unless event.target.tagName is 'A'
        @emit 'FormNeedsToBeChanged', yes, no
    else
      callback = (event) =>
        kd.utils.stopDOMEvent event
        return  unless event.target.tagName is 'A'
        @emit 'FormNeedsToBeChanged', no, no

    @password   = @getPassword()
    @tfcode     = @getTFCode()
    @button     = @getButton @getOption 'buttonTitle'
    @buttonLink = @getButtonLink @createButtonLinkPartial(), null, callback

    @on [ 'FormSubmitFailed', 'FormValidationFailed' ], @button.bound 'hideLoader'


  createButtonLinkPartial: ->

    teamData = utils.getTeamData()
    if teamData.profile
      { firstName, nickname, hash } = teamData.profile
      name = "#{firstName or '@'+nickname}"
      "Are you <img src='#{utils.getGravatarUrl 24, hash}'/> <a href='#'>#{name}</a>?"
    else
      "Want to join with a <a href='#'>fresh account</a>?"


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
