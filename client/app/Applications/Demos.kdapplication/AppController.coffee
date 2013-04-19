
class ChatListController extends KDListViewController

  constructor:->
    super
    @me = KD.whoami()

  loadView:->
    super
    list = @getListView()
    @loadItems()

  loadItems:(callback)->

    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    @me.fetchFollowersWithRelationship {}, {}, (err, accounts)=>
      @instantiateListItems accounts unless err

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message

class ChatListView extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "chat-list"
    options.tagName   = "ul"

    super options, data

class ChatListItem extends KDListItemView

  constructor:(options = {},data)->

    options.tagName  = "li"
    options.bind     = "mouseenter mouseleave"

    super options, data

    data = @getData()

    @avatar = new AvatarView {
      size    : {width: 30, height: 30}
      origin  : data
    }

    @conversation = null
    # @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <h3>{{#(profile.firstName)+' '+#(profile.lastName)}}</h3>
      </div>
    """

  click:(event)->
    unless @conversation
      @conversation = new InlineConversationWidget
      @addSubView @conversation
    else
      @conversation.$().toggleClass 'ready'

    # list     = @getDelegate()
    # mainView = list.getDelegate()
    # mainView.emit "MessageIsSelected", {item: @, event}

    # if event
    #   if event.target?.className is "delete-link"
    #     mainView.newMessageBar.createDeleteMessageModal()


class InlineConversationWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-conversation-widget'

    super options

    @messageInput = new KDHitEnterInputView
      type         : "text"
      placeholder  : "Type your message..."
      callback     : ->
        log "I will send this:", @getValue()

    KD.utils.defer => @setClass 'ready'

  toggle:->
    log "sdfsdf"

  pistachio:->
    """
      {{> @messageInput}}
    """

class DemosAppController extends AppController

  KD.registerAppClass @,
    name         : "Demos"
    route        : "Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->
    mainView.addSubView new KDHeaderView
      title : 'Demo App'

    chatListView = new ChatListView
      itemClass : ChatListItem

    chatController = new ChatListController
      view : chatListView

    chatController.loadItems()

    mainView.addSubView chatListView

#     mainView.addSubView button = new BottomChatRoom

# class BottomChatRoom extends JView

#   constructor:->

#     super

#     @tokenInput = tokenInput = new KDTokenizedInput
#       cssClass             : 'chat-input'
#       input                :
#         keydown            :
#           "alt super+right"   : (e)->
#             tokenInput.emit "chat.ui.splitPanel", e.which
#             e.preventDefault()
#           "alt alt+right"     : (e)->
#             tokenInput.emit "chat.ui.focusNextPanel"
#           "alt alt+left"      : (e)->
#             tokenInput.emit "chat.ui.focusPrevPanel"
#           "alt alt+backspace" : (e)->
#             tokenInput.emit "chat.ui.focusPrevPanel"

#       match                :
#         topic              :
#           regex            : /\B#\w.*/
#           # throttle         : 2000
#           wrapperClass     : "highlight-tag"
#           replaceSignature : "{{#(title)}}"
#           added            : (data)->
#             log "tag is added to the input", data
#           removed          : (data)->
#             log "tag is removed from the input", data
#           dataSource       : (token)->
#             appManager.tell "Topics", "fetchSomeTopics", selector : token.slice(1), (err, topics)->
#               # log err, topics
#               if not err and topics.length > 0
#                 tokenInput.showMenu {token, rule : "topic"}, topics

#         username           :
#           regex            : /\B@\w.+/
#           wrapperClass     : "highlight-user"
#           replaceSignature : "{{#(profile.firstName)}} {{#(profile.lastName)}}"
#           added            : (data)->
#             log "user is added to the input", data
#           removed          : (data)->
#             log "user is removed from the input", data
#           dataSource       : (token)->
#             # log token, "member"
#             appManager.tell "Members", "fetchSomeMembers", selector : token.slice(1), (err, members)->
#               # log err, members
#               if not err and members.length > 0
#                 tokenInput.showMenu {
#                   rule             : "username"
#                   itemChildClass   : MembersListItemView
#                   itemChildOptions :
#                     cssClass       : "honolulu"
#                     userInput      : token.slice(1)
#                   token
#                 }, members

#     @outputController = new KDListViewController

#     @output = @outputController.getView()

#     @sidebar = new KDView
#       cssClass : "room-sidebar"

#   pistachio:->

#     """
#       <section>
#         {{> @output}}
#         {{> @tokenInput}}
#       </section>
#       {{> @sidebar}}
#     """
