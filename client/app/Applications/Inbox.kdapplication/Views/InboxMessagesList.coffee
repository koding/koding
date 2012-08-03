class InboxMessagesList extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "inbox-list message-list"
    options.tagName   = "ul"

    super options,data

class InboxMessagesListItem extends KDListItemView

  constructor:(options = {},data)->

    options.tagName  = "li"
    options.cssClass = "unread"
    options.bind     = "mouseenter mouseleave"

    super options, data

    data = @getData()

    group = data.participants.map (participant)->
      constructorName : participant.sourceName
      id              : participant.sourceId
    .filter (participant, i, arr)=>
      if arr.length > 1 and @getSingleton('mainController').getVisitor().currentDelegate.getId() is participant.id
        return no
      else return yes

    @participants = new ProfileTextGroup {group}
    @avatar       = new AvatarView {
      size    : {width: 40, height: 40}
      origin  : group[0]
    }

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

    @unsetClass('unread') if @getData().getFlagValue('read')

  teaser:(text)->
    @utils.shortenText(text, minLength: 40, maxLength: 70) or ''

  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <h3>{{#(subject) or '(No title)'}}</h3>
        <p>{{@teaser #(body)}}</p>
        <footer>
          {{> @participants}} <time>{{$.timeago #(meta.createdAt)}}</time>
        </footer>
      </div>
    """

  mouseEnter:(event)->
    @setClass "shadowed"

  mouseLeave:(event)->
    @unsetClass "shadowed"

  makeAllItemsUnselected:()->
    inboxList = @getDelegate()
    inboxList.$("li").removeClass("active")

  makeItemSelected:()->
    @setClass "active"

  click:(event)->
    list     = @getDelegate()
    mainView = list.getDelegate()
    mainView.propagateEvent KDEventType : "MessageIsSelected", {item: @, event}
    @makeAllItemsUnselected()
    @makeItemSelected()
