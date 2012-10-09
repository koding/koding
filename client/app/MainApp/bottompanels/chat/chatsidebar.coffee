class BottomChatSideBar extends JView

  constructor: (options, data) ->

    super

    userController = new KDListViewController
      wrapper         : no
      scrollView      : no
      viewOptions     :
        type          : "chat-sidebar users"
        itemClass     : BottomChatUserItem
    ,
      items     : [
        { title : "sinan" }
        { title : "devrim" }
        { title : "chris" }
        { title : "aleksey" }
      ]

    channelController = new KDListViewController
      wrapper         : no
      scrollView      : no
      viewOptions     :
        type          : "chat-sidebar channels"
        itemClass  : BottomChatUserItem
    ,
      items     : [
        { title : "public" }
        { title : "python" }
        { title : "html" }
        { title : "nonsense" }
      ]

    @userList    = userController.getView()
    @channelList = channelController.getView()

    # @channelList.on 'viewAppended', =>
    #   log "e"

  show:-> @setClass "out"

  hide:-> @unsetClass "out"

  pistachio:->
    """
      <h2>Online</h2>
      {{> @userList}}
      <h2>Active Channels</h2>
      {{> @channelList}}
    """
