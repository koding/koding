JView           = require './../../core/jview'
LoginInputView  = require './../../login/logininputview'
TeamJoinTabForm = require './../forms/teamjointabform'


module.exports = class TeamJoinWithInvitedAccountForm extends TeamJoinTabForm

  constructor: ->

    super

    teamData = kd.utils.getTeamData()

    @username = new LoginInputView
      cssClass        : 'hidden'
      inputOptions    :
        placeholder   : 'pick a username'
        name          : 'username'
        defaultValue  : teamData.signup.username

    @password   = @getPassword()
    @tfcode     = @getTFCode()
    @button     = @getButton 'Done!'
    @buttonLink = @getButtonLink "Not you? <a href='#'>Create an account!</a>", (event) =>
      kd.utils.stopDOMEvent event
      return  unless event.target.tagName is 'A'

      @emit 'FormNeedsToBeChanged', no, no

    @on 'FormValidationFailed', @button.bound 'hideLoader'
    @on 'FormSubmitFailed', @button.bound 'hideLoader'


  submit: (formData) ->

    teamData = kd.utils.getTeamData()
    teamData.signup.alreadyMember = yes

    super formData


  pistachio: ->

      """
      {{> @username}}
      {{> @password}}
      {{> @tfcode}}
      <p class='dim'>
        Your email address indicates that you're already a Koding user,
        please type your password to proceed.<br>
        <a href='//#{kd.utils.getMainDomain()}/Recover' target='_self'>Forgot your password?</a>
      </p>
      <div class='TeamsModal-button-separator'></div>
      {{> @button}}
      {{> @buttonLink}}
      """
