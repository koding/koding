kookies            = require 'kookies'
getGroup           = require './util/getGroup'
whoami             = require './util/whoami'
envDataProvider    = require 'app/userenvironmentdataprovider'
kd                 = require 'kd'
KDModalView        = kd.ModalView
KDNotificationView = kd.NotificationView
KDObject           = kd.Object


module.exports = class NotificationController extends KDObject

  deleteUserCookie = -> kookies.expire 'clientId'

  displayEmailConfirmedNotification = (modal)->
    modal.off 'KDObjectWillBeDestroyed'
    new KDNotificationView
      title    : 'Thanks for confirming your e-mail address'
      duration : 5000

    return modal.destroy()


  constructor:->

    super

    kd.getSingleton('mainController').ready @bound 'init'


  init: ->

    @setListeners()
    @subscribeToRealtimeUpdates()


  subscribeToRealtimeUpdates:->

    @notificationChannel = null

    {realtime} = kd.singletons
    realtime.subscribeNotification (err, notificationChannel) =>

      @notificationChannel = notificationChannel

      return kd.warn 'notification subscription error', err  if err

      @notificationChannel.on 'message', (notification)=>

        @emit 'NotificationHasArrived', notification

        { contents, context, event } = notification

        return unless contents

        event = if contents.event then contents.event else event
        # TODO enable this with team product
        # event = unless context is getGroup().slug then "#{event}-off-context" else event
        # event is mainly -> ChannelUpdateHappened // do not delete this line. here for search purposes. - SY
        @emit event, contents  if event

      @notificationChannel.on 'social', (notification) =>
        { contents, context, event } = notification

        @emit event, contents  if event


  setListeners:->

    @on 'GuestTimePeriodHasEnded', deleteUserCookie

    @once 'EmailShouldBeConfirmed', ->
      {firstName, nickname} = whoami().profile
      kd.getSingleton('appManager').tell 'Account', 'displayConfirmEmailModal', name, nickname, (modal)=>
        @once 'EmailConfirmed', displayEmailConfirmedNotification.bind this, modal
        modal.on "KDObjectWillBeDestroyed", deleteUserCookie.bind this

    @on 'MachineListUpdated', (machineUId) ->
      envDataProvider.setLastUpdatedMachineUId machineUId
      kd.singletons.computeController.reset yes

    @on 'UsernameChanged', ({username, oldUsername}) ->
      # FIXME: because of this (https://app.asana.com/0/search/6604719544802/6432131515387)
      deleteUserCookie()

      new KDModalView
        title         : "Your username was changed"
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
          "Refresh":
            style     : "solid red medium"
            callback  : (event) -> location.replace '/Login'
          "Close"     :
            style     : "solid light-gray medium"
            callback  : (event) -> modal.destroy()

    @on 'UserBlocked', ({blockedDate}) ->
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
          "Ok"        :
            style     : "solid light-gray medium"
            callback  : (event) ->
              kookies.expire 'clientId'
              modal.destroy()
              global.location.reload yes

      # If not clicked on "Ok", kick him out after 10 seconds
      kd.utils.wait 10000, =>
        kookies.expire 'clientId'
        global.location.reload yes
