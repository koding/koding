kd                             = require 'kd'
_                              = require 'lodash'
articlize                      = require 'indefinite-article'
utils                          = require './../../core/utils'
MainHeaderView                 = require './../../core/mainheaderview'
TeamJoinByLoginForm            = require './../forms/teamjoinbyloginform'
TeamJoinBySignupForm           = require './../forms/teamjoinbysignupform'
TeamJoinWithInvitedAccountForm = require './../forms/teamjoinwithinvitedaccountform'


track = (action, properties = {}) ->

  properties.category = 'TeamJoin'
  properties.label    = 'JoinTab'
  utils.analytics.track action, properties

module.exports = class TeamJoinTab extends kd.TabPaneView

  constructor: (options = {}, data) ->

    options.cssClass           = kd.utils.curry 'username', options.cssClass
    options.loginForm        or= TeamJoinByLoginForm
    options.loginFormInvited or= TeamJoinWithInvitedAccountForm
    options.signupForm       or= TeamJoinBySignupForm
    options.email            or= utils.getTeamData().invitation?.email

    super options, data


  show: ->
    super
    @setOption 'email', utils.getTeamData().invitation?.email
    @createSubViews()
    @wrapper.setClass 'join'


  hide: ->
    super
    @destroySubViews()


  createSubViews: ->

    teamData       = utils.getTeamData()
    @alreadyMember = teamData.signup?.alreadyMember
    @forgotPassword = null  if @forgotPassword?

    @addSubView new MainHeaderView { cssClass : 'team', navItems : [] }

    wrapperCssClass = 'TeamsModal TeamsModal--groupCreation'
    wrapperCssClass = kd.utils.curry wrapperCssClass, 'alreadyMember'  if @alreadyMember
    @addSubView @wrapper = new kd.CustomHTMLView { cssClass: wrapperCssClass }

    @putAvatar @getOption 'email'  if @alreadyMember

    @wrapper.addSubView @intro = new kd.CustomHTMLView { tagName: 'p', cssClass: 'intro', partial: '' }
    @wrapper.addSubView @title = new kd.CustomHTMLView { tagName: 'h4', partial: @getModalTitle() }
    @wrapper.addSubView @desc  = new kd.CustomHTMLView { tagName: 'h5', cssClass: 'full', partial: @getDescription() }
    @addForm()

    @addForgotPasswordLink()


  getModalTitle: ->

    teamTitle  = kd.config.group.title
    return "Join #{utils.createTeamTitlePhrase teamTitle}"


  addForm: ->

    if @alreadyMember and @wantsToUseDifferentAccount
      @hideAvatar()
      @forgotPassword?.show()
      kd.utils.defer => @form.username.input.$().trigger 'focus'

      TeamJoinTabFormClass = @getOption 'loginForm'

    else if @alreadyMember
      @showAvatar()
      @forgotPassword?.show()
      kd.utils.defer => @form.password.input.$().trigger 'focus'

      TeamJoinTabFormClass = @getOption 'loginFormInvited'

    else
      @forgotPassword?.hide()
      @hideAvatar()
      kd.utils.defer =>
        if utils.getTeamData().invitation?.email
          @form.username.input.$().trigger 'focus'
        else
          @form.email.input.$().trigger 'focus'

      TeamJoinTabFormClass = @getOption 'signupForm'

    @form?.destroy()
    @form = new TeamJoinTabFormClass { callback: @bound 'submit' }
    @wrapper.addSubView @form

    @form.once 'FormNeedsToBeChanged', (isMember, needsDifferentAccount) =>
      @alreadyMember = isMember
      @wantsToUseDifferentAccount = needsDifferentAccount
      @clearValidations()
      @addForm()
      @updatePartials()
      @addForgotPasswordLink()


  updatePartials: ->

    @title.updatePartial @getModalTitle()
    @desc.updatePartial @getDescription()


  clearValidations: ->

    inputs = kd.FormView.findChildInputs this

    _.each inputs, (input) ->
      input.emit 'ValidationFeedbackCleared' # Reset the validations


  hideAvatar: ->

    @avatar?.hide()
    @intro.hide()


  showAvatar: ->

    @avatar?.show()
    @intro.show()


  putAvatar: (email) ->

    return  unless email

    @wrapper.addSubView @avatar = new kd.CustomHTMLView { tagName: 'figure' }
    @wrapper.getDomElement().addClass 'with-avatar'

    { getProfile, getGravatarUrl, getTeamData } = utils

    getProfile email,
      error   : =>
        @intro.updatePartial ''
        utils.storeNewTeamData 'profile', null
      success : (profile) =>
        { hash, firstName, nickname } = profile
        utils.storeNewTeamData 'profile', profile
        @intro.updatePartial "Hey #{firstName or '@' + nickname},"
        @avatar.addSubView new kd.CustomHTMLView
          tagName    : 'img'
          attributes : { src: getGravatarUrl 64, hash }


  getDescription: ->

    domains = kd.config.group.allowedDomains
    if @alreadyMember and @wantsToUseDifferentAccount
      "Please enter your <i>#{kd.config.domains.main}</i> username & password."
    else if @alreadyMember
      "Please enter your <i>#{kd.config.domains.main}</i> password."
    else if domains?.length > 1
      domainsPartial = utils.getAllowedDomainsPartial domains
      if /\*/.test kd.config.group.allowedDomains
      then 'This is a public team, you can use any email address to join!'
      else "You must have an email address from one of these domains #{domainsPartial} to join"
    else if domains?.length is 1
      if /\*/.test kd.config.group.allowedDomains
      then 'This is a public team, you can use any email address to join!'
      else "You must have #{articlize domains.first} <i>#{domains.first}</i> email address to join"
    else
      "Pick a username and password for your new <i>#{kd.config.domains.main}</i> account."


  addForgotPasswordLink: ->

    return  unless @alreadyMember
    return  if @forgotPassword

    @addSubView @forgotPassword = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'additional-info'
      partial  : '<p>Forgot your password? <a href="/Team/Recover?mode=join">Click here</a> to reset.</p>'


  submit: (formData) ->

    { username } = formData
    success      = =>
      track 'submitted join a team form'
      utils.storeNewTeamData 'join', formData
      utils.joinTeam
        error : ({ responseText }) =>
          @form.emit 'FormSubmitFailed'

          if /TwoFactor/.test responseText
            track 'needed two factor authentication'
            @form.showTwoFactor()
          else
            track 'failed to join a team'
            new kd.NotificationView { title : responseText }

    if @alreadyMember then success()
    else
      utils.usernameCheck username,
        success : ->
          track 'entered a valid username'
          success()
        error   : ({ responseJSON }) =>
          track 'entered an invalid username'

          unless responseJSON
            return new kd.NotificationView
              title: 'Something went wrong'

          { forbidden, kodingUser } = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new kd.NotificationView { title : msg }
          @form.emit 'FormSubmitFailed'
