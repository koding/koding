debug             = (require 'debug') 'groupscontroller'
kd                = require 'kd'

whoami            = require '../util/whoami'
kookies           = require 'kookies'
getGroup          = require '../util/getGroup'
getGroupStatus    = require '../util/getGroupStatus'
showError         = require '../util/showError'

remote            = require('../remote')
globals           = require 'globals'
GroupData         = require './groupdata'
remote_extensions = require 'app/remote-extensions'

module.exports = class GroupsController extends kd.Controller

  constructor: (options = {}, data) ->

    super options, data

    @isReady = no

    mainController    = kd.getSingleton 'mainController'
    { entryPoint }      = globals.config
    @groups           = {}
    @currentGroupData = new GroupData
    @currentGroupData.setGroup globals.currentGroup

    mainController.ready =>
      { slug } = entryPoint  if entryPoint?.type is 'group'
      @changeGroup slug

    @ready =>
      @on 'GroupDestroyed', ->
        # delete client id cookie, which is used for session authentication
        kookies.expire 'clientId'
        # send user to home page
        global.location.href = '/'

      @on 'InstanceChanged', (data) ->
        remote_extensions.updateInstance data?.contents

      @on 'InstanceDeleted', (data) ->
        remote_extensions.removeInstance data?.contents


  getCurrentGroup: ->
    FIXME = 'FIXME: array should never be passed'
    throw FIXME  if Array.isArray @currentGroupData.data
    return @currentGroupData.data


  getCurrentGroupStatus: -> getGroupStatus @getCurrentGroup()


  currentGroupHasStack: ->

    { stackTemplates } = @getCurrentGroup()

    return stackTemplates?.length > 0


  currentGroupIsNew: -> not @getCurrentGroup().stackTemplates


  filterXssAndForwardEvents: (target, events) ->
    events.forEach (event) =>
      target.on event, (rest...) =>
        debug 'got notification for group', rest...
        rest = remote.revive rest
        @emit event, rest...


  knownEvents = [
    'StackTemplateChanged'
    'GroupStackTemplateRemoved'
    'InstanceChanged'
    'InstanceDeleted'
    'GroupDestroyed'
    'GroupJoined'
    'MembershipRoleChanged'
    'InvitationChanged'
    'GroupLeft'
    'StackAdminMessageCreated'
    'SharedStackTemplateAccessLevel'
  ]

  openSocialGroupChannel: (group, callback = -> ) ->

    { realtime, socialapi } = kd.singletons

    if realtime.isPubNubEnabled()

      socialapi.channel.byId { id: group.socialApiChannelId }, (err, channel) =>
        return callback err  if err

        socialapi.registerAndOpenChannel group, channel, (err, registeredChan) =>
          return callback err  if err

          realtimeChan = registeredChan?.delegate
          return callback 'realtime chan is not set'  unless realtimeChan

          @filterXssAndForwardEvents realtimeChan, knownEvents
          callback null

    else

      realtime.nodeNotificationClient.on 'group:message', (notification) =>

        debug 'got notification from nodeNotificationClient', notification

        { event } = notification
        if event in knownEvents
          notification = remote.revive notification
          @emit event, notification


  changeGroup: (groupName = 'koding', callback = kd.noop) ->

    return callback()  if @currentGroupName is groupName

    @currentGroupName   = groupName

    remote.cacheable groupName, (err, models) =>
      if err then callback err
      else if models?
        [group] = models
        if group.bongo_.constructorName isnt 'JGroup'
          @changeGroup 'koding'
        else
          @setGroup groupName
          @currentGroupData.setGroup group
          callback null, groupName, group
          @openSocialGroupChannel getGroup()
          @emit 'ready'

  getUserArea: ->
    @userArea ? { group:
      if globals.config.entryPoint?.type is 'group'
      then globals.config.entryPoint.slug
      else (kd.getSingleton 'groupsController').currentGroupName }

  setUserArea: (userArea) ->
    @userArea = userArea

  getGroupSlug: -> @currentGroupName

  setGroup: (groupName) ->
    @currentGroupName = groupName
    @setUserArea {
      group: groupName, user: whoami().profile.nickname
    }

  joinGroup: (group, callback) ->
    group.join (err, response) ->
      return showError err  if err?
      callback err, response
      kd.getSingleton('mainController').emit 'JoinedGroup'

  acceptInvitation: (group, callback) ->
    whoami().acceptInvitation group, (err, res) =>
      mainController = kd.getSingleton 'mainController'
      mainController.once 'AccountChanged', callback.bind this, err, res
      mainController.accountChanged whoami()

  ignoreInvitation: (group, callback) ->
    whoami().ignoreInvitation group, callback

  cancelGroupRequest: (group, callback) ->
    whoami().cancelRequest group.slug, callback

  canEditGroup: ->
    ['admin', 'owner'].reduce (prole, role) ->
      prole or (role in globals.userRoles)
    , no

  ###*
   *  Sets given stack template as current group's default stack template
   *
   *  @param  {JStackTemplate}  stackTemplate
   *  @param  {Func}            callback  [ err ]
  ###
  setDefaultTemplate: (stackTemplate, callback = kd.noop) ->

    { computeController }   = kd.singletons
    { slug } = currentGroup = @getCurrentGroup()

    if slug is 'koding'
      return callback 'Setting stack template for koding is disabled'

    # Share given stacktemplate with group first
    stackTemplate.setAccess 'group', (err) =>
      return callback err  if err

      # Modify group data to use this stackTemplate as default
      # TMS-1919: Needs to be changed to update stackTemplates list
      # instead of setting it as is for the given stacktemplate ~ GG

      currentGroup.modify { stackTemplates: [ stackTemplate._id ] }, (err) =>
        return callback err  if err

        @getCurrentGroup().setAt 'stackTemplates', [ stackTemplate._id ]

        new kd.NotificationView
          title : "Team (#{slug}) stack has been saved!"
          type  : 'mini'

        # Re-call create default stack flow to make sure it exists
        # TMS-1919: This is possibly not needed for multiple stacks
        # since we will allow users to select one stacktemplate from
        # available stacktemplates list of group ~ GG

        computeController.createDefaultStack { force: yes }

        debug 'setDefaultTemplate sending notification', stackTemplate._id
        # Warn other group members about stack template update
        currentGroup.sendNotification 'StackTemplateChanged', stackTemplate._id

        callback null
