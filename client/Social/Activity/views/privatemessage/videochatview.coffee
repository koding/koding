class VideoChatView extends KDView

  JView.mixin @prototype


  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'video-chat', options.cssClass

    super options, data

    @hide()

    @accessModal = null


  show: ->

    super

    @getDelegate().emit 'VideoContainerVisible'


  hide: ->

    super

    @getDelegate().emit 'VideoContainerHidden'


  showAccessModal: ->

    @accessModal = new KDModalView { title : 'Please allow access' }


  hideAccessModal: ->

    @accessModal?.destroy()
    @accessModal = null


