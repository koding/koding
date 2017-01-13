$              = require 'jquery'
kd             = require 'kd'
async          = require 'async'
remote         = require 'app/remote'
whoami         = require 'app/util/whoami'
Tracker        = require 'app/util/tracker'
SlackUserItem  = require './views/slackuseritem'
CustomLinkView = require 'app/customlinkview'

titleDecorator = (channel) -> if channel.is_group then channel.name else "##{channel.name}"

titleHelper = (count, group) ->
  if count is 1
  then "Invite 1 member in #{group}"
  else "Invite all #{count} members in #{group}"

getSelectedMembers = (listController) ->
  selected = listController.getListItems()
    .filter (item) -> item.checkBox.getValue()
    .map (item) -> item.getData()


module.exports = class HomeTeamConnectSlack extends kd.CustomHTMLView

  SLACKBOT_ID   = 'USLACKBOT'
  OAUTH_URL     = "#{location.origin}/api/social/slack/oauth"
  USERS_URL     = "#{location.origin}/api/social/slack/users"
  CHANNELS_URL  = "#{location.origin}/api/social/slack/channels"
  MESSAGING_URL = "#{location.origin}/api/social/slack/message"
  ICON_URL      = 'https://koding.com/a/images/logos/notify_logo.png'

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'slack-invite-view', options.cssClass

    super options, data

    @addSubView @loader = new kd.LoaderView
      showLoader : yes
      size       :
        width    : 30
        height   : 30

    $.ajax
      method  : 'GET'
      url     : CHANNELS_URL
      success : @bound 'createInviterViews'
      error   : @bound 'createInformationView'


  createInformationView : ->
    @loader.hide()

    @addSubView info = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'information'
      partial  : 'Invite your teammates using your company\'s team on Slack.'

    info.addSubView button = new kd.ButtonView
      cssClass : 'solid medium green slack-oauth'
      title    : 'Import from  <cite></cite>'
      callback : ->
        location.assign OAUTH_URL
        Tracker.track Tracker.TEAMS_CONNECTED_SLACK


  reset: ->

    @destroySubViews()
    @updatePartial ''
    @createInformationView()


  createInviterViews: ->
    @loader.hide()

    @addSubView @mainSection = new kd.CustomHTMLView
    @createChangerView()

    $.ajax
      method  : 'GET'
      url     : CHANNELS_URL
      success : (res) => @createChannelInviter res.channels.concat res.groups or []
      error   : @bound 'reset'

    $.ajax
      method  : 'GET'
      url     : USERS_URL
      success : (res) => @createIndividualInviter res
      error   : @bound 'reset'


  createChangerView: ->

    @addSubView changerView = new kd.CustomHTMLView
      cssClass : 'hidden'

    changerView.addSubView header = new kd.CustomHTMLView
      tagName  : 'h3'
      partial  : 'Use a different Slack team:'

    header.addSubView new CustomLinkView
      cssClass : 'HomeAppView--button primary changeTeam'
      title    : 'CHANGE SLACK TEAM'
      click    : -> location.assign OAUTH_URL

    @on 'ListAdded', -> changerView.show()


  createChannelInviter: (channels) ->

    @counts      = {}
    @allChannels = {}

    selectOptions = channels
      .map (channel) =>

        @allChannels[channel.name] = channel
        @counts[channel.name]      = channel.num_members or channel.members.length

        return { title: titleDecorator(channel), value: channel.name }

    @mainSection.addSubView new kd.CustomHTMLView
      tagName : 'h3'
      partial : 'You can invite all the users in a Slack channel:'

    @mainSection.addSubView wrapper = new kd.CustomHTMLView
      cssClass: 'clearfix'

    wrapper.addSubView select = new kd.SelectBox
      defaultValue  : 'general'
      callback      : (name) =>
        title = titleHelper @counts[name], titleDecorator @allChannels[name]
        @inviteChannel.setTitle title
      cssClass      : 'fl'
      selectOptions : selectOptions

    wrapper.addSubView @inviteChannel = new CustomLinkView
      cssClass : 'HomeAppView--button primary fr inviteChannel'
      title    : titleHelper @counts.general, '#general'
      click    : =>

        return  unless @users

        channelMemberIds = @allChannels[select.getValue()].members
        recipients       = @users.filter (user) -> user.id in channelMemberIds

        @sendMessages recipients


  createIndividualInviter: (users) ->

    @users = users = users.filter (user) -> user.id isnt SLACKBOT_ID

    @mainSection.addSubView new kd.CustomHTMLView
      tagName : 'h3'
      partial : 'Or you can invite individual members:'

    listController = new kd.ListViewController
      itemClass         : SlackUserItem
      wrapper           : no
      scrollView        : no
      lazyLoadThreshold : 10
      viewOptions       :
        cssClass        : 'slack-user-list'
      lazyLoaderOptions :
        spinnerOptions  :
          loaderOptions : { shape: 'spiral', color: '#a4a4a4' }
          size          : { width: 20, height: 20 }
    ,
      items             : users

    @mainSection.addSubView list = listController.getView()

    list.addSubView @inviteIndividual = new CustomLinkView
      cssClass : 'HomeAppView--button primary fr inviteIndividual'
      title    : 'Invite selected members'
      click    : => @sendMessages getSelectedMembers listController

    list.on 'ItemValueChanged', =>
      selected = getSelectedMembers listController
      switch l = selected.length
        when 0
          @inviteIndividual.setTitle 'Invite selected members'
          @inviteIndividual.disable()
          return
        when 1 then title = 'Invite 1 selected member'
        else        title = "Invite #{l} selected members"

      @inviteIndividual.enable()
      @inviteIndividual.setTitle title

    @on 'InvitationsAreSent', ->
      listController.getListItems()
        .filter (item) -> item.checkBox.getValue()
        .forEach (item) -> item.checkBox.setValue off
      list.emit 'ItemValueChanged'

    @emit 'ListAdded'

  sendMessages: (recipients) ->

    invitations = recipients.map ({ profile }) ->
      email     : profile.email
      firstName : profile.first_name
      lastName  : profile.last_name

    remote.api.JInvitation.create
      invitations : invitations
      returnCodes : yes
      noEmail     : yes
    , (err, res) =>

      if err or not res
        return new kd.NotificationView { title : 'Something went wrong, please try again!' }

      invites = {}

      res.forEach (invite) ->
        invites[invite.email.toLowerCase()] =
          code           : invite.code
          alreadyInvited : invite.alreadyInvited


      queue = recipients.map (recipient) -> (fin) ->

        return fin()  unless invite = invites[recipient.profile.email.toLowerCase()]

        inviter = whoami().profile.firstName
        group   = kd.singletons.groupsController.getCurrentGroup()
        title   = group.title or group.slug
        link    = "#{location.origin}/Invitation/#{invite.code}"
        msg     = "#{inviter} has invited you to #{title} team on Koding!"

        $.ajax
          url              : MESSAGING_URL
          method           : 'POST'
          headers          :
            Accept         : 'application/json'
            'Content-Type' : 'application/json'
          data             : JSON.stringify
            channel        : recipient.id
            text           : ''
            params         :
              as_user      : no
              username     : "#{inviter} from Koding!"
              icon_url     : ICON_URL
              attachments  : [{
                color      : '#5373A1'
                title      : msg
                title_link : link
                text       : "Click the link below to join #{title}. \n #{link}"
                thumb_url  : ICON_URL
                fallback   : "#{msg} #{link}"
              }]

          success: -> fin()
          error: -> fin 'error'

      async.parallel queue, (err, res) =>
        # make this smarter
        return new kd.NotificationView { title: 'There were some errors' }  if err

        new kd.NotificationView { title: 'All invitations are sent!' }

        @emit 'InvitationsAreSent'
