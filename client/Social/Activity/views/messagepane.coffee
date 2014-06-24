class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    {itemClass, type} = @getOptions()
    {typeConstant}    = @getData()

    @createParticipantsView() if typeConstant is 'privatemessage'

    @listController = new ActivityListController {itemClass}

    @createInputWidget()

    @bindChannelEvents()

    @on 'LazyLoadThresholdReached', @bound 'lazyLoad'  if typeConstant in ['group', 'topic']

    {windowController} = KD.singletons

    windowController.addFocusListener (focused) =>

      @glance()  if focused and @active


    if typeConstant in ['privatemessage', 'post']

      @listController.getListView().once 'ItemWasAdded', (item) =>

        listView = @listController.getListItems().first.commentBox.controller.getListView()
        listView.on 'ItemWasAdded', @bound 'scrollDown'

    else

      @listController.getListView().on 'ItemWasAdded', @bound 'scrollUp'


  scrollDown: ->

    return  unless @active

    listView = @listController.getListItems().first.commentBox.controller.getListView()
    unless @separator
      @separator = new KDView cssClass : 'new-messages'
      listView.addSubView @separator

    KD.utils.defer -> window.scrollTo 0, document.body.scrollHeight


  scrollUp: ->

    return  unless @active

    window.scrollTo 0, 0


  createParticipantsView : ->

    {participantsPreview} = @getData()

    @participantsView = new KDCustomHTMLView
      cssClass    : 'chat-heads'
      partial     : '<span class="description">Private conversation between</span>'

    @participantsView.addSubView heads = new KDCustomHTMLView
      cssClass    : 'heads'

    for participant in participantsPreview

      participant.id = participant._id

      heads.addSubView new AvatarView
        size      :
          width   : 30
          height  : 30
        origin    : participant

    heads.addSubView @newParticipantButton = new KDButtonView
      cssClass    : 'new-participant'
      iconOnly    : yes
      callback    : ->
        new PrivateMessageRecipientModal
          blacklist : participantsPreview.map (item) -> item._id
          position  :
            top     : @getY() + 50
            left    : @getX() - 150


  createInputWidget: ->

    return  if @getOption("type") in ['post', 'privatemessage']

    channel = @getData()

    @input = new ActivityInputWidget {channel}


  bindChannelEvents: ->

    {socialapi} = KD.singletons
    socialapi.onChannelReady @getData(), (channel) =>

      return  unless channel

      channel
        .on 'MessageAdded',   @bound 'prependMessage'
        .on 'MessageRemoved', @bound 'removeMessage'


  appendMessage: (message) -> @listController.addItem message, @listController.getItemCount()

  prependMessage: (message) -> @listController.addItem message, 0

  removeMessage: (message) -> @listController.removeItem null, message


  viewAppended: ->

    @addSubView @participantsView if @participantsView
    @addSubView @input  if @input
    @addSubView @listController.getView()
    @populate()


  show: ->

    super

    KD.utils.wait 1000, @bound 'glance'
    KD.utils.defer @bound 'focus'


  glance: ->

    data = @getData()
    {id, typeConstant} = data
    {socialapi, appManager} = KD.singletons

    app  = appManager.get 'Activity'
    item = app.getView().sidebar.selectedItem

    return  unless item?.count
    # no need to send updatelastSeenTime or glance
    # when checking publicfeeds
    return  if typeConstant is 'group'

    if typeConstant is 'post'
    then socialapi.channel.glancePinnedPost   messageId : id, @bound 'glanced'
    else socialapi.channel.updateLastSeenTime channelId : id, @bound 'glanced'


  glanced: ->

    @separator?.destroy()
    @separator = null


  focus: ->

    if @input
      @input.input.$().trigger 'click'
    else
      @listController.getListItems().first?.commentBox.inputForm.input.setFocus()



  populate: ->

    @fetch null, (err, items = []) =>

      return KD.showError err  if err

      console.time('populate')
      @listController.hideLazyLoader()
      @listController.instantiateListItems items
      console.timeEnd('populate')

      KD.utils.defer @bound 'focus'


  fetch: (options = {}, callback)->

    {
      name
      type
      channelId
    }            = @getOptions()
    data         = @getData()
    {appManager} = KD.singletons

    options.name      = name
    options.type      = type
    options.channelId = channelId

    # if it is a post it means we already have the data
    if type is 'post'
    then KD.utils.defer -> callback null, [data]
    else appManager.tell 'Activity', 'fetch', options, callback


  lazyLoad: ->
    @listController.showLazyLoader()

    {appManager} = KD.singletons
    last         = @listController.getItemsOrdered().last
    from         = last.getData().meta.createdAt.toISOString()

    @fetch {from}, (err, items = []) =>
      @listController.hideLazyLoader()

      return KD.showError err  if err

      items.forEach @lazyBound 'appendMessage'


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()

