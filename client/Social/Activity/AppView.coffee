class ActivityAppView extends KDScrollView

  JView.mixin @prototype

  headerHeight = 0

  {entryPoint, permissions, roles} = KD.config

  isGroup        = -> entryPoint?.type is 'group'
  isKoding       = -> entryPoint?.slug is 'koding'
  isMember       = -> 'member' in roles
  canListMembers = -> 'list members' in permissions
  isPrivateGroup = -> not isKoding() and isGroup()


  constructor:(options = {}, data)->

    options.cssClass   = 'content-page activity'
    options.domId      = 'content-page-activity'

    super options, data

    {entryPoint}           = KD.config
    {appStorageController} = KD.singletons
    @_lastMessage          = null

    @appStorage = appStorageController.storage 'Activity', '2.0'
    @sidebar    = new ActivitySidebar tagName : 'aside', delegate : this
    @tabs       = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes

    @appStorage.setValue 'liveUpdates', off



  lazyLoadThresholdReached: -> @tabs.getActivePane()?.emit 'LazyLoadThresholdReached'


  viewAppended: ->

    @addSubView @sidebar
    @addSubView @tabs


  open: (type, slug) ->

    @sidebar.selectItemByRouteOptions type, slug

    item = @sidebar.selectedItem or @sidebar.public
    data = item.getData()
    name = if slug then "#{type}-#{slug}" else type
    pane = @tabs.getPaneByName name

    if pane
    then @tabs.showPane pane
    else @createTab name, data


  createTab: (name, data) ->

    channelId = data.id
    type      = data.typeConstant

    paneClass = switch type
      when 'topic' then TopicMessagePane
      else MessagePane

    @tabs.addPane pane = new paneClass {name, type, channelId}, data

    return pane


  refreshTab: (name) ->

    pane = @tabs.getPaneByName name

    pane?.refresh()

    return pane


  showNewMessageModal: ->

    @open 'public'  unless @tabs.getActivePane()

    modal = new KDModalViewWithForms
      title                   : 'New Private Message'
      cssClass                : 'private-message'
      content                 : ''
      overlay                 : yes
      width                   : 660
      height                  : 'auto'
      tabs                    :
        forms                 :
          Message             :
            callback          : =>
              {body} = modal.modalTabs.forms.Message.inputs
              {send} = modal.modalTabs.forms.Message.buttons
              val = body.getValue()
              {router, socialapi} = KD.singletons
              socialapi.message.sendPrivateMessage body : val, (err, channels) ->
                send.hideLoader()
                if err then KD.showError err
                else
                  [channel] = channels
                  debugger
                  router.handleRoute "/Activity/Message/#{channel.id}"
                  @_lastMessage = null
                  modal.destroy()
            buttons           :
              send            :
                title         : 'Send'
                style         : 'solid-green'
                type          : 'submit'
              cancel          :
                title         : 'Nevermind'
                style         : 'modal-cancel'
                callback      : (event) =>
                  @_lastMessage = null
                  modal.destroy()
            fields            :
              body            :
                label         : ''
                name          : 'body'
                type          : 'textarea'
                defaultValue  : @_lastMessage  if @_lastMessage
                placeholder   : "What's on your mind? Don't forget to @mention people you want this message to be sent."
                keyup         : =>
                  @_lastMessage = modal.modalTabs.forms.Message.inputs.body.getValue()
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : 'You forgot to put some message in.'

    modal.on 'KDModalViewDestroyed', KD.singletons.router.bound 'back'

    return modal
