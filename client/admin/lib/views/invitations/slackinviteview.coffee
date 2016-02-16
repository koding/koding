$             = require 'jquery'
kd            = require 'kd'
SlackUserItem = require './slackuseritem'


titleDecorator = (channel) -> if channel.is_group then channel.name else "##{channel.name}"

titleHelper = (count, group) ->
  if count is 1
  then "Invite 1 member in #{group}"
  else "Invite all #{count} members in #{group}"

getSelectedMembers = (listController) ->
  selected = listController.getListItems()
    .filter (item) -> item.checkBox.getValue()
    .map (item) -> item.getData()


module.exports = class SlackInviteView extends kd.CustomScrollView

  SLACKBOT_ID = 'USLACKBOT'
  OAUTH_URL   = "#{location.origin}/api/social/slack/oauth"

  constructor: (options = {}, data) ->

    options.cssClass = 'slack-invite-view'

    super options, data

    @createInformationView()


  createInformationView : ->

    @wrapper.addSubView info = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'information'
      partial  : 'Invite your teammates using your company\'s Slack account.'

    info.addSubView button = new kd.ButtonView
      cssClass : 'solid medium green slack-oauth'
      title    : 'Import from  <cite></cite>'
      callback : =>

        cb = =>
          kd.utils.killRepeat repeat
          info.hide()
          @createInviterViews()

        oauth_window = window.open(
          OAUTH_URL,
          "slack-oauth-window",
          "width=800,height=#{window.innerHeight},left=#{Math.floor (screen.width/2) - 400},top=#{Math.floor (screen.height/2) - (window.innerHeight/2)}"
        )

        repeat = kd.utils.repeat 500, -> cb()  if oauth_window.closed




  createInviterViews: ->

    $.ajax
      type : 'GET'
      url  : '/api/social/slack/channels'
      success : (res) =>
        @createChannelInviter res.channels.concat res.groups or []

    $.ajax
      type : 'GET'
      url  : '/api/social/slack/users'
      success : (res) =>
        @createIndividualInviter res


  createChannelInviter: (channels) ->

    @counts      = {}
    @allChannels = {}

    selectOptions = channels
      .map (channel) =>

        @allChannels[channel.name] = channel
        @counts[channel.name]      = channel.num_members or channel.members.length

        return { title: titleDecorator(channel), value: channel.name }

    @wrapper.addSubView new kd.CustomHTMLView
      tagName : 'h3'
      partial : 'You can invite all the users in a slack channel:'

    @wrapper.addSubView wrapper = new kd.CustomHTMLView
      cssClass: 'clearfix'

    wrapper.addSubView select = new kd.SelectBox
      defaultValue  : 'general'
      callback      : (name) =>
        title = titleHelper @counts[name], titleDecorator @allChannels[name]
        @inviteChannel.setTitle title
      cssClass      : 'fl'
      selectOptions : selectOptions

    wrapper.addSubView @inviteChannel = new kd.ButtonView
      cssClass : 'solid medium green invite-members'
      title    : titleHelper @counts.general, '#general'


  createIndividualInviter: (users) ->

    users = users.filter (user) -> user.id isnt SLACKBOT_ID

    @wrapper.addSubView new kd.CustomHTMLView
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
          loaderOptions : shape: 'spiral', color: '#a4a4a4'
          size          : width: 20, height: 20
    ,
      items             : users

    @wrapper.addSubView list = listController.getView()

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


    list.addSubView @inviteIndividual = new kd.ButtonView
      cssClass : 'solid medium green invite-members fr'
      title    : 'Invite selected members'
      disabled : yes
      callback : ->
        selected = getSelectedMembers listController
        console.log selected
