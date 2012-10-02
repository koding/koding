class BottomPanelController extends KDController

  loadView:(bottomPanel)->

    @bottomPanel = bottomPanel
    @wc          = @getSingleton("windowController")

    bottomPanel.on "ToggleBottomPanel", => @toggle()
    bottomPanel.on "ReceivedClickElsewhere", (event)=> @hide event

    bottomPanel.addSubView @chatSidebar = new BottomChatSideBar
      cssClass : "chat-sidebar"

    bottomPanel.addSubView splitWrapper = new KDScrollView
      cssClass : "split-wrapper"


    splitWrapper.addSubView @split = new SlidingSplit
      cssClass : "chat-split"
      sizes    : [null]
      views    : [new KDView]

    @split.on "panelSplitted", (panel)->
      panel.addSubView new KDView

  togglePanel:(name)->

  createPanel:(name)->

  destroyPanel:(name)->

  showPanel:(name)->

  hidePanel:(name)->



class BottomChatSideBar extends JView

  constructor: (options, data) ->

    super

    userController = new KDListViewController
      wrapper         : no
      scrollView      : no
      viewOptions     :
        type          : "chat-sidebar users"
        itemClass  : BottomChatUserItem
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

    @channelList.on 'viewAppended', =>
      log "e"

  show:-> @setClass "out"

  hide:-> @unsetClass "out"

  pistachio:->
    """
      <h2>Online</h2>
      {{> @userList}}
      <h2>Active Channels</h2>
      {{> @channelList}}
    """

class BottomChatUserItem extends KDListItemView

  viewAppended: JView::viewAppended

  pistachio:-> """<a href=#>{{ #(title)}}</a>"""

  # partial:-> """#{@getData().title}"""
