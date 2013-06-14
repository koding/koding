class InboxMessagesList extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "inbox-list message-list"
    options.tagName   = "ul"

    super options, data

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
      if arr.length > 1 and KD.whoami().getId() is participant.id
        return no
      else return yes

    @participants = new ProfileTextGroup {group}
    @avatar       = new AvatarView {
      size    : {width: 40, height: 40}
      origin  : group[0]
    }

    @participants.hide() if group.length is 0

    @deleteLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : '#'
      cssClass    : 'delete-link'

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

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
        {{> @deleteLink}}
        <h3>{{#(subject) or '(No title)'}}</h3>
        <p>{{@teaser #(body)}}</p>
        <footer>
          {{> @participants}} {{> @timeAgoView}}
        </footer>
      </div>
    """

  mouseEnter:(event)->
    @setClass "shadowed"

  mouseLeave:(event)->
    @unsetClass "shadowed"

  makeAllItemsUnselected:->
    inboxList = @getDelegate()
    inboxList.$("li").removeClass("active")

  makeItemSelected:->
    @setClass "active"

  click:(event)->
    list     = @getDelegate()
    mainView = list.getDelegate()
    mainView.emit "MessageIsSelected", {item: @, event}
    @makeAllItemsUnselected()
    @makeItemSelected()

    if event
      if event.target?.className is "delete-link"
        mainView.newMessageBar.createDeleteMessageModal()

class LoadMoreMessagesItem extends KDListItemView

  constructor:(options = {},data)->

    options.tagName  = "li"
    options.cssClass = "unread"

    super options, data

  partial:(data)->
    "Load more messages..."
