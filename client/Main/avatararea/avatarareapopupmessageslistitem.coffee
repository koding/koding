class PopupMessageListItem extends KDListItemView
  constructor:(options,data)->
    options = $.extend
      tagName : "li"
    ,options

    super options,data

    @initializeReadState()

    group   = {} unless data.participants
    group or= data.participants.map (participant)->
      constructorName : participant.sourceName
      id              : participant.sourceId

    @participants = new ProfileTextGroup {group}
    @avatar       = new AvatarStaticView {
      size    : {width: 40, height: 40}
      origin  : group[0]
    }

  initializeReadState:->
    if @getData().getFlagValue('read')
      @unsetClass 'unread'
    else
      @setClass 'unread'

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  teaser:(text)->
    utils.shortenText(text, minLength: 40, maxLength: 70) or ''

  click:(event)->
    appManager = KD.getSingleton "appManager"
    appManager.open 'Inbox'
    appManager.tell "Inbox", "goToMessages", @
    popupList = @getDelegate()
    popupList.emit 'AvatarPopupShouldBeHidden'

  pistachio:->
    """
    <span class='avatar'>{{> @avatar}}</span>
    <div class='right-overflow'>
      <a href='#'>{{#(subject) or '(No title)'}}</a><br/>
      {{@teaser #(body)}}
      <footer>
        <time>{{> @participants}} {{$.timeago #(meta.createdAt)}}</time>
      </footer>
    </div>
    """
