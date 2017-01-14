kd                = require 'kd'
remote            = require('./remote')
{ htmlDecode }    = require 'htmlencode'
KDObject          = kd.Object
isMyNotification  = require 'app/util/isMyNotification'

module.exports = class PageTitleController extends KDObject

  constructor: ->

    super

    @defaultTitle = global.document.title
    @focused      = yes
    @blinker      = null
    @count        = 0

    { notificationController, windowController } = kd.singletons
    notificationController.on 'MessageAddedToChannel', @bound 'processNotification'

    windowController.addFocusListener (focused) => @resetCount()  if @focused = focused


  processNotification: (notification) ->

    return  if @focused
    return  if isMyNotification notification

    { id, typeConstant } = notification.channelMessage

    return  if typeConstant isnt 'privatemessage'

    { socialapi } = kd.singletons

    socialapi.message.byId { id }, (err, message) =>
      id              = message.account._id
      constructorName = message.account.constructorName
      remote.cacheable constructorName, id, (err, account) =>
        @blink "#{account.profile.nickname} messaged you!"

    @count++
    @update "(#{@count}) #{@getAppTitle()}"


  blink: (title) ->

    kd.utils.killRepeat @blinker  if @blinker
    defaultState = on
    @blinker = kd.utils.repeat 5000, =>
      unless defaultState
      then @update "(#{@count}) #{@getAppTitle()}"
      else @update title
      defaultState = not defaultState


  resetCount: ->

    @count = 0
    kd.utils.killRepeat @blinker  if @blinker
    @update @getAppTitle()


  update: (title) ->

    title = htmlDecode title

    { groupsController } = kd.singletons

    groupsController.ready ->
      if group = groupsController.getCurrentGroup()
        title = "#{htmlDecode group.title} - Koding | #{title}"

      global.document.title = "#{title}"


  reset: -> @update @defaultTitle

  get: -> return global.document.title or ''

  getRaw: -> return @get().replace /\([0-9]+\)\s(.*)/, '$1'

  getAppTitle: -> return kd.singletons.appManager.getFrontApp()?.options.name or 'Koding'
