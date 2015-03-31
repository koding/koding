kd = require 'kd'
getNick = require 'app/util/nick'

module.exports = class ChatVideoView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ChatVideo', options.cssClass

    super options, data

    @publisherView = null

    @createContainer()


  createContainer: ->

    @container = new kd.CustomHTMLView { cssClass: 'ChatVideo-container' }
    @addSubView @container


  getContainer: -> @container


  show: ->

    @emit 'ViewWillShow'

    super

    @emit 'ViewDidShow'


  hide: ->

    @emit 'ViewWillHide'

    super

    @emit 'ViewDidHide'


