#Broker.channel_auth_endpoint = KD.config.apiUri+'/1.0/channel/auth';
#Broker.channel_auth_endpoint = 'http://localhost:8008/auth'

# THIS OVERRIDE NEEDS TO WAIT
# NOT YET TOTALLY INTEROPERABLE
# WITH Encoder.htmlDecode

# Encoder.htmlEncode = do->

#    htmlMap =
#      '&' : 'amp'
#      '<' : 'lt'
#      '"' : 'quot'
#      '<' : 'lt'
#      '>' : 'gt'
#      "'" : '#39'
#      '`' : '#96'
#      '!' : '#33'
#      '@' : '#36'
#      '%' : '#37'
#      '(' : '#40'
#      ')' : '#41'
#      '=' : '#61'
#      '+' : '#43'
#      '{' : '#123'
#      '}' : '#125'
#      '[' : '#91'
#      ']' : '#93'

#    (str)-> str.replace /(&(?!\w\w+;)|'|<|>|"|'|`|\!|\@|\$|\%|\(|\)|\=|\+|\{|\}|\[|\])/g, (match)-> "&#{htmlMap[match]};"

mainController = new MainController


KD.remote.on 'loggedInStateChanged', (account)->
  mainController.accountChanged account, {connected: no}

# Pistachio.MODE = if KD.env is 'dev' then 'development' else 'production'

#$.cookie 'clientId', localStorage.clientId

# Cacheable = new Cacheable

# setTimeout ->
#   appManager.openApplication("Chat")
# ,5000

firstLoad = yes
connectionLostModalId = null
connectionLostNotification = null

initConnectionEvents = _.once (conn)->
  conn.on 'end', ->
    #
    # CONNECTIVITY NOTIFICATIONS PART START
    #
    setTimeout -> # to avoid modal to appear on page refresh

      if connectionLostNotification?
        connectionLostNotification.destroy()
        connectionLostNotification = null

      # THE MODAL APPEARS WHEN CONNECTION IS LOST
      unless connectionLostModalId?
        connectionLostModalId = KDModalController.createAndShowNewModal
          type    : 'blocking'
          title   : "Server connection lost"
          content : """
            <div class='modalformline'>
              Your internet connection may be down, or our server is.<br/><br/>
              If you have unsaved work please close this dialog and <br/><strong>back up your unsaved work locally</strong> until the connection is re-established.<br/><br/>
              <span class='small-loader fade in'></span> Trying to reconnect...
            </div>
            """
          height  : "auto"
          overlay : yes
          buttons :
            "Close and Refresh later" :
              style     : "modal-clean-red"
              callback  : ()->
                @propagateEvent KDEventType:'KDModalShouldClose'
                connectionLostModalId = null
                if connectionLostNotification?
                  connectionLostNotification.destroy()
                  connectionLostNotification = null

                updateModalActive = no

                # THE NOTIFICATION APPEARS WHEN MODAL WAS CLOSED BEFORE CONNECTION RE-ESTABLISHES
                connectionLostNotification = new KDNotificationView
                  title    : "Server Connection Has Been Lost"
                  content  : "Trying to reconnect..., changes will not be saved until server reconnects, please back up locally."
                  duration : 999999999
    ,500

KD.remote.connect -> console.log 'koding is now connected to the backend'


  #initConnectionEvents conn
#
#  if connectionLostModalId?
#    (KDModalController.getModalById connectionLostModalId)?.destroy()
#    connectionLostModalId = null
#
#    # THE MODAL APPEARS WHEN CONNECTION IS RE-ESTABLISHED
#    connectionLostModalId = KDModalController.createAndShowNewModal
#      type    : 'blocking'
#      title   : "Server connection <i style='color:green;'>established!</i>"
#      content : """
#        <div class='modalformline'>
#          <strong style='color:green;'>Connection re-established,</strong><br/><br/>
#          If you have unsaved work please close this dialog and <br/><strong>back up your unsaved work locally</strong> then refresh the page!
#        </div>
#        """
#      height  : "auto"
#      overlay : yes
#      buttons :
#        "Refresh Now" :
#          style     : "modal-clean-red"
#          callback  : ()->
#            @propagateEvent KDEventType:'KDModalShouldClose'
#            connectionLostModalId = null
#            location.reload yes
#        "Refresh Later" :
#          style     : "modal-cancel"
#          callback  : ()->
#            @propagateEvent KDEventType:'KDModalShouldClose'
#            connectionLostModalId = null
#            if connectionLostNotification?
#              connectionLostNotification.destroy()
#              connectionLostNotification = null
#            updateModalActive = no
#            # THE NOTIFICATION APPEARS WHEN MODAL WAS CLOSED AFTER CONNECTION RE-ESTABLISHES
#            connectionLostNotification = new KDNotificationView
#              title    : "Please back up your work and refresh!"
#              content  : "Changes will not be saved until you refresh the page."
#              duration : 999999999
#
#  if connectionLostNotification?
#    connectionLostNotification.destroy()
#    connectionLostNotification = null
#    # THE NOTIFICATION APPEARS WHEN MODAL WAS CLOSED BEFORE CONNECTION RE-ESTABLISHES
#    # IS BEING UPDATED TO A NEW RE-ESTABLISHED NOTIFICATION
#    connectionLostNotification = new KDNotificationView
#      title    : "Connection re-established!"
#      content  : "If you backed up you can refresh now, changes will not be saved until you refresh."
#      duration : 999999999
#
#  #
#  # CONNECTIVITY NOTIFICATIONS PART END
#  #
#
#  if firstLoad
#    # Cacheable.init()
#    api.JVisitor = class JVisitor extends api.JVisitor
#      constructor:(options)->
#        super()
#        if options.startListening
#          @start (err)->
#            throw err if err
#
#    Bongo.Model::fetchPrivateChannel = do ->
#      {JChannel} = api
#      channels = []
#      (callback)->
#        JChannel.fetch "#{@getId()}_private", (err, secretChannelId)=>
#          if err
#            callback err
#          else if secretChannelId?
#            if channel = channels[secretChannelId]
#              callback null, channel
#            else
#              channel = @mq.subscribe secretChannelId
#              channels[secretChannelId] = channel
#              callback null, channel
#          else callback new KodingError 'bad user!'
#
#    AccountMixin.init(api)
#
#    mainController.setVisitor new api.JVisitor startListening: yes
#
#    cyclePrivateChannel =(delegate)->
#      KD.remote.api.JChannel.fetch delegate.getId()+'_private', (err, channelId)->
#        channel = KD.remote.mq?.subscribe channelId
#        channel.bind 'change.channel', ->
#          KD.remote.mq.unsubscribe channelId
#          cyclePrivateChannel delegate
#        ###channel.bind 'message', (msg)->
#          console.log msg###
#
#    changeLoginState = (delegate)->
#      cyclePrivateChannel(delegate)
#      mainController.getVisitor().currentDelegate = delegate
#
#    mainController.getVisitor().on 'change.login', changeLoginState
#    mainController.getVisitor().on 'change.logout', changeLoginState
#
#    KD.socketConnected()
#    firstLoad = no
#
#  updateModalActive = no
#  KD.remote.api.JVisitor.getVersion (err, version)->
#    return if KD.version is version or updateModalActive
#    updateModalActive = yes
#
#    modal = new KDBlockingModalView
#      title   : "There is a new version available!"
#      content : "<div class='modalformline'>Please save your work and refresh!
#                  <br><br><span class='small-loader fade in'></span> Please report bugs in the update to the beta feedback site</div>"
#      height  : "auto"
#      overlay : yes
#      buttons :
#        "Refresh Now" :
#          style     : "modal-clean-red"
#          callback  : ()->
#            modal.destroy()
#            location.reload yes
#        "Refresh Later" :
#          style     : "modal-cancel"
#          callback  : ()->
#            modal.destroy()
#            updateModalActive = no
#

# if location.hostname is "localhost"
#   a = setInterval ->
#     myVal = localStoragejsReloaderLastReload
#     $.get "/js/requiresReload.txt",(response)->
#       if response is "0"
#         clearInterval a
#       else
#         if response isnt myVal
#           localStorage.jsReloaderLastReload = response
#           a = new KDNotificationView
#             type : "growl"
#             title : "Oh no, I'm going down..."
#             duration : 500
#           location.reload yes
#
#           #
#           # BSOD SECTION :)
#           #
#           # setTimeout ->
#           #   location.assign "http://localhost:3000:/bsod.html"
#           # ,1000
#           #
#
#   ,1000
