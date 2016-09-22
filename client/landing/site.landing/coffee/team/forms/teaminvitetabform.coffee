kd = require 'kd'
JView          = require './../../core/jview'


module.exports = class TeamInviteTabForm extends kd.FormView

  JView.mixin @prototype
  count = 0
  createInput = ->
    count++
    new kd.InputView
      placeholder : 'email@domain.com'
      name        : "invitee#{count}"


  constructor: (options = {}, data) ->

    options.cssClass = 'clearfix'

    super options, data

    @label = new kd.LabelView
      title : 'Allow sign up and team discovery with a company email address'
      for   : 'allow'

    @checkbox = new kd.InputView
      defaultValue : on
      type         : 'checkbox'
      name         : 'allow'
      label        : @label

    @input1 = createInput()
    @input2 = createInput()
    @input3 = createInput()

    @add = new kd.ButtonView
      title    : 'ADD INVITATION'
      style    : 'TeamsModal-button compact TeamsModal-button--gray add'
      callback : @bound 'addInvitee'

    @button = new kd.ButtonView
      title      : 'NEXT'
      style      : 'TeamsModal-button'
      attributes : { testpath : 'invite-button' }
      type       : 'submit'


  addInvitee: ->

    input   = createInput()
    wrapper = new kd.CustomHTMLView { cssClass : 'login-input-view' }
    wrapper.addSubView input
    @addSubView wrapper, '.additional'
    input.setFocus()


  pistachio: ->

    """
    <div class='login-input-view'>{{> @input1}}</div>
    <div class='login-input-view'>{{> @input2}}</div>
    <div class='login-input-view'>{{> @input3}}</div>
    <div class='additional'></div>
    {{> @add}}
    <p class='dim'>if you’d like, you can send invitations after you finish setting up your team.</p>
    {{> @button}}
    """
