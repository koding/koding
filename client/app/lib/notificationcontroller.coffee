debug              = (require 'debug') 'app:notificationcontroller'
kookies            = require 'kookies'
getGroup           = require 'app/util/getGroup'
whoami             = require 'app/util/whoami'
kd                 = require 'kd'
articlize          = require 'indefinite-article'
KDModalView        = kd.ModalView
KDNotificationView = kd.NotificationView
KDObject           = kd.Object
ContentModal = require 'app/components/contentModal'
EnvironmentFlux = require 'app/flux/environment'

actions = require 'app/flux/environment/actiontypes'
remote_extensions  = require 'app/remote-extensions'


module.exports = class NotificationController extends KDObject

  deleteUserCookie = -> kookies.expire 'clientId'

  displayEmailConfirmedNotification = (modal) ->
    modal.off 'KDObjectWillBeDestroyed'
    new KDNotificationView
      title    : 'Thanks for confirming your e-mail address'
      duration : 5000


    return modal.destroy()


  constructor: ->

    super

    kd.getSingleton('mainController').ready @bound 'init'


  init: ->

    @setListeners()
    @subscribeToRealtimeUpdates()


  subscribeToRealtimeUpdates: ->

    @notificationChannel = null

    { realtime } = kd.singletons
    realtime.subscribeNotification (err, notificationChannel) =>

      @notificationChannel = notificationChannel

      return kd.warn 'notification subscription error', err  if err

      @notificationChannel.on ['message', 'social'], (notification) =>

        debug 'got notification', notification

        # filter notifications according to group slug
        return  unless notification?.context is getGroup().slug

        { contents, context, event } = notification
        @emit event, contents  if event


  setListeners: ->

    { computeController: { storage }, reactor } = kd.singletons

    @on 'GuestTimePeriodHasEnded', deleteUserCookie

    @on 'SessionHasEnded', ({ clientId }) ->

      return deleteUserCookie()  unless clientId

      # Delete user cookie if current session is not to be preserved.
      # Session initiated password change procedure is meant to be kept.
      if clientId isnt kookies.get 'clientId'
        deleteUserCookie()


    @on 'MachineShareListUpdated', (data = {}) ->

      { machineId, action } = data

      debug 'machine share list updated', data

      if machineId
        storage.machines.fetch '_id', machineId, force = yes
          .then (machine) -> machine.reviveUsers { permanentOnly: yes }


    @on 'StackOwnerUpdated', (data = {}) =>

      { stackId } = data

      storage.stacks.fetch '_id', stackId
        .then (stack) => @emit 'DisabledUserStackAdded', { stack }
        .catch (err) -> debug 'failed to fetch stack', stackId


      debug 'StackOwnerUpdated', data


    @on 'MachineListUpdated', (data = {}) =>

      { machineUId, action, permanent } = data
      { appManager } = kd.singletons

      switch action

        when 'removed'
          if ideInstance = appManager.getInstance 'IDE', 'mountedMachineUId', machineUId
            ideInstance.showUserRemovedModal()

          if machine = storage.machines.get 'uid', machineUId
            storage.machines.pop machine

          @emit 'MachineShare:Removed', { machine }

        when 'added'
          storage.machines.fetch 'uid', machineUId
            .then (machine) =>
              @emit 'MachineShare:Added', { machine }
              return machine

            .catch (err) ->
              kd.warn 'Failed to fetch machine', { err, machineUId }
              return err

      debug 'MachineListUpdated', data


    @on 'UsernameChanged', ({ username, oldUsername }) ->
      # FIXME: because of this (https://app.asana.com/0/search/6604719544802/6432131515387)
      deleteUserCookie()

      new KDModalView
        title         : 'Your username was changed'
        overlay       : yes
        content       :
          """
          <div class="modalformline">
          Your username has been changed to <strong>#{username}</strong>.
          Your <em>old</em> username <strong>#{oldUsername}</strong> is
          now available for registration by another Koding user.  You have
          been logged out.  If you wish, you may close this box, and save
          your work locally.
          </div>
          """
        buttons       :
          'Refresh':
            style     : 'solid red medium'
            callback  : (event) -> location.replace '/Login'
          'Close'     :
            style     : 'solid light-gray medium'
            callback  : (event) -> modal.destroy()

    @on 'UserBlocked', ({ blockedDate }) ->
      modal = new KDModalView
        title         : "Permission denied. You've been banned."
        overlay       : yes
        overlayClick  : no
        cancelable    : no
        content       :
          """
          <div class="modalformline">
            Hello,
            This account has been put on suspension by Koding moderators due to violation of our <a href="https://koding.com/Legal">acceptable use policy</a>. The ban will be in effect until <strong>#{blockedDate}</strong> at which time you will be able to log back in again. If you have any questions regarding this ban, please write to <a href='mailto:ban@koding.com?subject=Username: #{whoami().profile.nickname}'>ban@koding.com</a> and allow 2-3 business days for us to research and reply. Even though your account is banned, all your data is safe and will be accessible once the ban is lifted.<br><br>

            Please note, repeated violations of our <a href="https://koding.com/Legal">acceptable use policy</a> will result in the permanent deletion of your account.<br><br>

            Team Koding
          </div>
          """
        buttons       :
          'Ok'        :
            style     : 'solid light-gray medium'
            callback  : (event) ->
              kookies.expire 'clientId'
              modal.destroy()
              global.location.reload yes

      # If not clicked on "Ok", kick him out after 10 seconds
      kd.utils.wait 10000, ->
        kookies.expire 'clientId'
        global.location.reload yes

    @on 'UserKicked', ->
      # delete client id cookie, which is used for session authentication
      kookies.expire 'clientId'

      # send user to Banned page
      global.location.href = '/Banned'


    @on 'InstanceChanged', (data) ->
      remote_extensions.updateInstance data


    @on 'InstanceDeleted', (data) ->
      remote_extensions.removeInstance data


    @on 'KloudActionOverAPI', (change) ->
      kd.singletons.computeController.handleChangesOverAPI change
