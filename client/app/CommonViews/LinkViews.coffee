class KDAccount extends bongo.EventEmitter
  @fromId = (_id)->
    account = new KDAccount
    bongo.cacheable 'JAccount', _id, (err, accountData)->
      for own prop, val of accountData
        account[prop] = val
      setTimeout ->
        account.emit 'update', account
      , 1
    return account

  constructor:(data)->
    $.extend @, data if data

class LinkView extends KDCustomHTMLView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href      : '#'
    , options
    delete options.attributes.href if options.tagName isnt "a"

    data or= fake : yes
    data.profile or= {}
    data.profile.firstName or= "a koding"
    data.profile.lastName  or= "user"

    super options, data
    if data.fake and options.origin
      @loadFromOrigin options.origin

  loadFromOrigin:(origin)->

    callback = (data)=>
      @setData data
      @render()

    if origin.constructorName
      bongo.cacheable origin.constructorName, origin.id, (err, origin)=>
        callback origin
    else
      callback origin

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

class ProfileLinkView extends LinkView

  constructor:(options = {}, data)->

    # options.tooltip =
    #   gravity   : "s"
    #   delayIn   : 120
    #   offset    : 1

    super options, data

    # nickname = data?.profile?.nickname
    # @$().attr "href","/#!/member/#{nickname}" if nickname
    @setClass "profile"

  # render:->

  #   nickname = @getData().profile?.nickname
  #   if nickname
  #     @$().attr "href","/#!/member/#{nickname}"
  #     @updateTooltip title : "@#{nickname}"
  #   super

  pistachio:->

    super "{{#(profile.firstName)+' '+#(profile.lastName)}}"

  click:(event)->

    appManager.tell "Members", "createContentDisplay", @getData()
    event.preventDefault()
    event.stopPropagation()
    no

class TagLinkView extends LinkView

  constructor:(options = {}, data)->
    options.expandable ?= no
    if not options.expandable and data?.title.length > 16
      options.tooltip =
        title     : data.title
        placement : "above"
        delayIn   : 120
        offset    : 1
    super options, data

    @setClass "ttag expandable"
    @unsetClass "expandable" unless options.expandable

  pistachio:->
    super "{{#(title)}}"

  click:->
    tag = @getData()
    appManager.tell "Topics", "createContentDisplay", tag

class LinkGroup extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName         = 'div'
    options.cssClass        = 'link-group'
    options.subItemClass  or= ProfileLinkView
    options.itemsToShow   or= 3
    options.totalCount    or= data?.length or options.group?.length or 0
    options.hasMore         = options.totalCount > options.itemsToShow

    super options, data

    if data?
      @createParticipantSubviews()
    else if options.group
      @loadFromOrigins options.group

  loadFromOrigins:(group)->

    callback = (data)=>
      @setData data
      @createParticipantSubviews()
      @render()

    if group[0]?.constructorName
      lastFour = group.slice -4
      bongo.cacheable lastFour, (err, bucketContents)=>
        callback bucketContents
    else
      callback group

  itemClass:(options, data)->
    new (@getOptions().subItemClass) options, data

  createParticipantSubviews:->
    participants = @getData()
    for participant, index in participants
      @["participant#{index}"] = @itemClass {}, participant
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    # log "in pistachio again",">>>>>>>>>>>>>>"
    participants = @getData()
    {hasMore, totalCount, group} = @getOptions()

    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        new FollowedModalView {group}, @getData()

    sep = ' '
    if participants[0] instanceof bongo.api.JAccount
      sep = ', '
    switch totalCount
      when 0 then ""
      when 1 then "{{> @participant0}}"
      when 2 then "{{> @participant0}} and {{> @participant1}}"
      when 3 then "{{> @participant0}}#{sep}{{> @participant1}} and {{> @participant2}}"
      when 4 then "{{> @participant0}}#{sep}{{> @participant1}}#{sep}{{> @participant2}} and {{> @participant3}}"
      else "{{> @participant0}}#{sep}{{> @participant1}}#{sep}{{> @participant2}} and {{> @more}}"

  render:->
    # log "rendering",">>>>>>>>>>>>>>"
    @createParticipantSubviews()


class ActivityChildViewTagGroup extends LinkGroup

  pistachio:->
    # log "in pistachio again",">>>>>>>>>>>>>>"
    participants = @getData()
    {hasMore, totalCount, group} = @getOptions()

    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        new FollowedModalView {group}, @getData()

    switch totalCount
      when 0 then ""
      when 1 then "in {{> @participant0}}"
      when 2 then "in {{> @participant0}}{{> @participant1}}"
      when 3 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}"
      when 4 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}{{> @participant3}}"
      else "in {{> @participant0}}{{> @participant1}}{{> @participant2}}and {{> @more}}"

class FollowedModalView extends KDModalView

  titleMap = ->
    account : "members"
    tag     : "topics"

  listControllerMap = ->
    account : MembersListViewController
    tag     : KDListViewController

  listItemMap = ->
    account : MembersListItemView
    tag     : ModalTopicsListItem

  constructor:(options = {}, data)->

    participants = data

    if participants[0] instanceof bongo.api.JAccount
      @type = "account"
    else if participants[0] instanceof bongo.api.JTag
      @type = "tag"

    options.title    or= titleMap()[@type]
    options.height   = "auto"
    options.overlay  = yes
    options.cssClass = "modal-topic-wrapper"
    options.buttons  =
      Close :
        style : "modal-clean-gray"
        callback : =>
          @destroy()

    super

  viewAppended:->
    @addSubView @loader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#cccccc"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @loader.show()

    @prepareList()
    @setPositions()

  putList: (participants) ->
    controller = new KDListViewController
      view              : new KDListView
        subItemClass    : listItemMap()[@type]
        cssClass        : "modal-topic-list"
    , items             : participants

    controller.getListView().on "CloseTopicsModal", =>
      @destroy()

    controller.on "AllItemsAddedToList", =>
      @loader.destroy()

    @addSubView controller.getView()

  prepareList:->

    {group} = @getOptions()

    if group
      bongo.cacheable group, (err, participants)=>
        if err then warn err
        else @putList participants
        ###
          bongo.api.JTag.markFollowing participants, (err, result)=>
            if err then warn err
            else @putList result
        ###
    else
      @putList @getData()


class AvatarView extends LinkView
  constructor:(options,data)->
    options = $.extend
      cssClass    : ""
      size        :
        width     : 50
        height    : 50
    ,options
    options.cssClass = "avatarview #{options.cssClass}"
    super options,data

  click:(event)->
    event.stopPropagation()
    account = @getData()
    appManager.tell "Members", "createContentDisplay", account
    return no

  render:->
    return unless @getData()
    {profile} = @getData()
    options = @getOptions()
    host = "#{location.protocol}//#{location.host}/"
    @$().attr "title", options.title or "#{Encoder.htmlDecode profile.firstName}'s avatar"
    fallbackUrl = "url(#{location.protocol}//gravatar.com/avatar/#{profile.hash}?size=#{options.size.width}&d=#{encodeURIComponent(host + 'images/defaultavatar/default.avatar.' + options.size.width + '.png')})"
    @$().css "background-image", fallbackUrl

  viewAppended:->
    @render() if @getData()

class AvatarStaticView extends AvatarView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'span'
      attributes  : ''
    ,options
    super options, data

  click:->
    yes

class AvatarSwapView extends AvatarView
  constructor:(options,data)->
    options = $.extend
      cssClass    : "profile-avatar"
    ,options
    super options,data

  click:-> noop

  setFileUpload:->
    if @swapAvatarView and @swapAvatarView.isInDom()
      @swapAvatarView.destroy()
    else
      @swapAvatarView = swapAvatarView = new KDFileUploadView
        limit        : 1
        preview      : "thumbs"
        extensions   : ["png","jpg","jpeg","gif"]
        fileMaxSize  : 500
        totalMaxSize : 700
        title        : "Drop a picture here!"
      @addSubView @swapAvatarView

class AutoCompleteAvatarView extends AvatarView
  constructor:(options,data)->
    options = $.extend
      size        :
        width     : 20
        height    : 20
    ,options
    options.cssClass = "avatarview #{options.cssClass}"
    super options,data

class ProfileTextGroup extends LinkGroup
  constructor:(options, data)->
    options = $.extend
      tagName       : 'span'
      cssClass      : 'link-group'
      subItemClass  : ProfileTextView
    , options
    super options, data

  click: -> yes

class ProfileTextView extends ProfileLinkView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'span'
      attributes  : ''
    ,options
    super options, data

  click: -> yes

class AutoCompleteProfileTextView extends ProfileTextView
  highlightMatch:(str, isNick=no)->
    {userInput} = @getOptions()
    unless userInput
      str
    else
      str = str.replace RegExp(userInput, 'gi'), (match)=>
        if isNick then @setClass 'nick-matches'
        return "<b>#{match}</b>"

  pistachio:->
    "{{@highlightMatch #(profile.firstName)+' '+#(profile.lastName)}}" +
      if @getOptions().shouldShowNick then """
        <span class='nick'>
          (@{{@highlightMatch #(profile.nickname), yes}})
        </span>
        """
      else ''
