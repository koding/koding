kd                             = require 'kd.js'
_                              = require 'lodash'
articlize                      = require 'indefinite-article'
utils                          = require './../../core/utils'
MainHeaderView                 = require './../../core/mainheaderview'
TeamJoinByLoginForm            = require './../forms/teamjoinbyloginform'
TeamJoinBySignupForm           = require './../forms/teamjoinbysignupform'
TeamJoinWithInvitedAccountForm = require './../forms/teamjoinwithinvitedaccountform'
TeamLoginAndCreateTabForm      = require './../forms/teamloginandcreatetabform'

track = (action) ->

  category = 'TeamJoin'
  label    = 'JoinTab'
  utils.analytics.track action, { category, label }

module.exports = class TeamJoinTab extends kd.TabPaneView

  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'username', options.cssClass

    super options, data

    teamData       = utils.getTeamData()
    @alreadyMember = teamData.signup?.alreadyMember
    domains        = kd.config.group.allowedDomains

    @addSubView new MainHeaderView { cssClass: 'team', navItems: [] }

    wrapperCssClass = 'TeamsModal TeamsModal--groupCreation'
    wrapperCssClass = kd.utils.curry wrapperCssClass, 'alreadyMember'  if @alreadyMember
    @addSubView @wrapper = new kd.CustomHTMLView { cssClass: wrapperCssClass }

    teamTitle  = kd.config.group.title
    modalTitle = "Join #{utils.createTeamTitlePhrase teamTitle}"

    @putAvatar()  if @alreadyMember

    @wrapper.addSubView @intro = new kd.CustomHTMLView { tagName: 'p', cssClass: 'intro', partial: '' }
    @wrapper.addSubView new kd.CustomHTMLView { tagName: 'h4', partial: modalTitle }
    @wrapper.addSubView new kd.CustomHTMLView { tagName: 'h5', partial: @getDescription() }
    @addForm()

    @addForgotPasswordLink()


  addForm: ->

    TeamJoinTabFormClass = if @alreadyMember and @wantsToUseDifferentAccount
      @hideAvatar()
      TeamJoinByLoginForm
    else if @alreadyMember
      @showAvatar()
      TeamJoinWithInvitedAccountForm
    else
      @hideAvatar()
      TeamJoinBySignupForm

    @form?.destroy()
    @form = new TeamJoinTabFormClass { callback: @bound 'joinTeam' }
    @wrapper.addSubView @form

    @form.once 'FormNeedsToBeChanged', (isMember, needsDifferentAccount) =>
      @alreadyMember = isMember
      @wantsToUseDifferentAccount = needsDifferentAccount
      @clearValidations()
      @addForm()


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


  putAvatar: ->

    @wrapper.addSubView @avatar = new kd.CustomHTMLView { tagName: 'figure' }

    { getProfile, getGravatarUrl, getTeamData } = utils
    { invitation: { email } }                   = getTeamData()

    getProfile email,
      error   : ->
      success : (profile) =>
        { hash, firstName, nickname } = profile
        utils.storeNewTeamData 'profile', profile
        @intro.updatePartial "Hey #{firstName or '@' + nickname},"
        @avatar.addSubView new kd.CustomHTMLView
          tagName    : 'img'
          attributes : { src: getGravatarUrl 64, hash }


  getDescription: ->
    desc = if @alreadyMember
      "Please enter your <i>koding.com</i> password."
    else if domains?.length > 1
      domainsPartial = utils.getAllowedDomainsPartial domains
      "You must have an email address from one of these domains #{domainsPartial} to join"
    else if domains?.length is 1
      "You must have #{articlize domains.first} <i>#{domains.first}</i> email address to join"
    else
      "Please choose a username and password for your new Koding account."


  addForgotPasswordLink: ->

    return  unless @alreadyMember

    @addSubView new kd.CustomHTMLView {
      tagName: 'section'
      partial: '''
        <p>
          Forgot your password? <a href="/Team/Recover?mode=join">Click here</a> to reset.
        </p>'''
    }


  joinTeam: (formData) ->

    { username } = formData
    success      = =>
      track 'submitted join a team form'
      utils.storeNewTeamData 'join', formData
      utils.joinTeam
        error : ({responseText}) =>
          @form.emit 'FormSubmitFailed'

          if /TwoFactor/.test responseText
            track 'needed two factor authentication'
            @form.showTwoFactor()
          else
            track 'failed to join a team'
            new kd.NotificationView title : responseText

    if @alreadyMember then success()
    else
      utils.usernameCheck username,
        success : ->
          track 'entered a valid username'
          success()
        error   : ({responseJSON}) =>
          track 'entered an invalid username'

          unless responseJSON
            return new kd.NotificationView
              title: 'Something went wrong'

          {forbidden, kodingUser} = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new kd.NotificationView title : msg
          @form.emit 'FormSubmitFailed'
