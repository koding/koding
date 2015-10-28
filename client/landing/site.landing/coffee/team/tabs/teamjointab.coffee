articlize                      = require 'indefinite-article'
MainHeaderView                 = require './../../core/mainheaderview'
TeamJoinByLoginForm            = require './../forms/teamjoinbyloginform'
TeamJoinBySignupForm           = require './../forms/teamjoinbysignupform'
TeamJoinWithInvitedAccountForm = require './../forms/teamjoinwithinvitedaccountform'

TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamJoinTab extends KDTabPaneView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'username', options.cssClass

    super options, data

    teamData       = KD.utils.getTeamData()
    @alreadyMember = teamData.signup?.alreadyMember
    domains        = KD.config.group.allowedDomains

    @addSubView new MainHeaderView { cssClass: 'team', navItems: [] }
    @addSubView @wrapper = new KDCustomHTMLView { cssClass: 'TeamsModal TeamsModal--groupCreation' }

    teamTitle  = KD.config.group.title
    modalTitle = "Join #{KD.utils.createTeamTitlePhrase teamTitle}"

    @putAvatar()  if @alreadyMember

    @wrapper.addSubView @intro = new KDCustomHTMLView { tagName: 'p', cssClass: 'intro', partial: '' }
    @wrapper.addSubView new KDCustomHTMLView { tagName: 'h4', partial: modalTitle }
    @wrapper.addSubView new KDCustomHTMLView { tagName: 'h5', partial: @getDescription() }
    @addForm()


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
      @addForm()


  hideAvatar: ->

    @avatar?.hide()
    @intro.hide()


  showAvatar: ->

    @avatar?.show()
    @intro.show()


  putAvatar: ->

    @wrapper.addSubView @avatar = new KDCustomHTMLView { tagName: 'figure' }

    { getProfile, getGravatarUrl, getTeamData } = KD.utils
    { invitation: { email } }                   = getTeamData()

    getProfile email,
      error   : ->
      success : (profile) =>
        { hash, firstName, nickname } = profile
        KD.utils.storeNewTeamData 'profile', profile
        @intro.updatePartial "Hey #{firstName or '@' + nickname},"
        @avatar.addSubView new KDCustomHTMLView
          tagName    : 'img'
          attributes : { src: getGravatarUrl 64, hash }


  getDescription: ->
    desc = if @alreadyMember
      "Please enter your <i>koding.com</i> password."
    else if domains?.length > 1
      domainsPartial = KD.utils.getAllowedDomainsPartial domains
      "You must have an email address from one of these domains #{domainsPartial} to join"
    else if domains?.length is 1
      "You must have #{articlize domains.first} <i>#{domains.first}</i> email address to join"
    else
      "Please choose a username and password for your new Koding account."


  joinTeam: (formData) ->

    { username } = formData
    success      = =>
      track 'submitted join a team form'
      KD.utils.storeNewTeamData 'join', formData
      KD.utils.joinTeam
        error : ({responseText}) =>
          if /TwoFactor/.test responseText
            track 'needed two factor authentication'
            @form.showTwoFactor()
          else
            track 'failed to join a team'
            new KDNotificationView title : responseText

    if @alreadyMember then success()
    else
      KD.utils.usernameCheck username,
        success : ->
          track 'entered a valid username'
          success()
        error   : ({responseJSON}) =>
          track 'entered an invalid username'

          unless responseJSON
            return new KDNotificationView
              title: 'Something went wrong'

          {forbidden, kodingUser} = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new KDNotificationView title : msg


track = (action) ->

  category = 'TeamJoin'
  label    = 'JoinTab'
  KD.utils.analytics.track action, { category, label }
