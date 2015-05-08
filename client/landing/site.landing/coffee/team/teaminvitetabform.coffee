JView             = require './../core/jview'
CustomLinkView    = require './../core/customlinkview'

module.exports = class TeamInviteTabForm extends KDFormView

  JView.mixin @prototype
  count = 0
  createInput = ->
    count++
    new KDInputView
      placeholder : "email@domain.com"
      name        : "invitee#{count}"


  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @label = new KDLabelView
      title : 'Allow sign up and team discovery with a company email address'
      for   : 'allow'

    @checkbox = new KDInputView
      defaultValue : on
      type         : 'checkbox'
      name         : 'allow'
      label        : @label

    @input1 = createInput()
    @input2 = createInput()
    @input3 = createInput()

    @add = new KDButtonView
      title    : 'ADD INVITATION'
      style    : 'SignupForm-button compact SignupForm-button--gray add'
      callback : @bound 'addInvitee'

    @skip = new CustomLinkView
      title    : 'Skip this step'
      cssClass : 'SignupForm-linkButton skip'
      href     : '/Team/username'

    @button = new KDButtonView
      title      : 'NEXT'
      style      : 'SignupForm-button SignupForm-button--green'
      attributes : testpath : 'invite-button'
      type       : 'submit'


  addInvitee: ->

    input   = createInput()
    wrapper = new KDCustomHTMLView cssClass : 'login-input-view'
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
    {{> @skip}}{{> @button}}
    """