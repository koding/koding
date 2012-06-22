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
    bongo.cacheable origin.constructorName, origin.id, (err, origin)=>
      @setData origin
      @render()
      @$().attr "href","/#!/#{origin.profile.nickname}" 
      # @$().twipsy title : "@#{origin.profile.nickname}", placement : "left"

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

class ProfileLinkView extends LinkView
  constructor:->
    super
    @setClass "profile"

  pistachio:->
    super "{{#(profile.firstName)+' '+#(profile.lastName)}}"

  click:->
    account = @getData()
    appManager.tell "Members", "createContentDisplay", account

class TagLinkView extends LinkView
  constructor:->
    super
    @setClass "ttag"

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

    if @getData()?
      @createParticipantSubviews()
    else if options.group
      @loadFromOrigins options.group
  
  loadFromOrigins:(group)->

    three = group.slice(-3)
    bongo.cacheable three, (err, bucketContents)=>
      @setData bucketContents
      @createParticipantSubviews()
      @render()
  
  itemClass:(options, data)->

    new (@getOptions().subItemClass) options, data
  
  createParticipantSubviews:->

    participants = @getData()
    for participant, index in participants
      @["participant#{index}"] = @itemClass {}, participant
    @setTemplate @pistachio()
    @template.update()
  
  pistachio:->

    participants = @getData()
    {hasMore, totalCount} = @getOptions()
    tmpl = switch participants.length
      when 1 then "{{> @participant0}}"
      when 2 then "{{> @participant0}} and {{> @participant1}}"
      when 3
        sep = if @participant0.getData() instanceof bongo.api.JAccount then ', ' else ' '
        "{{> @participant0}}#{sep}{{> @participant1}}#{if hasMore then sep else ' and'} {{> @participant2}}"
    tmpl += " and <a href='#' class='more'>#{totalCount-3} more</a>" if hasMore
    return tmpl

class ActivityChildViewTagGroup extends LinkGroup

  render:->

    @createParticipantSubviews()
  
  pistachio:->

    participants = @getData()
    {hasMore, totalCount} = @getOptions()

    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{participants.length-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : ->
        new FollowedModalView {}, participants

    switch participants.length
      when 0 then ""
      when 1 then "in {{> @participant0}}"
      when 2 then "in {{> @participant0}}{{> @participant1}}"
      when 3 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}"
      when 4 then "in {{> @participant0}}{{> @participant1}}{{> @participant2}}{{> @participant3}}"
      else "in {{> @participant0}}{{> @participant1}}{{> @participant2}}and {{> @more}}"

      
class FollowedModalView extends KDModalView
  
  titleMap = ->
    account : "Followed members:"
    tag     : "Followed tags:"
  
  listControllerMap = ->
    account : MembersListViewController
    tag     : KDListViewController
  
  listItemMap = ->
    account : MembersListItemView
    tag     : TopicsListItemView
  
  constructor:(options = {}, data)->
    
    participants = data

    if participants[0] instanceof bongo.api.JAccount
      @type = "account"
    else if participants[0] instanceof bongo.api.JTag
      @type = "tag"
    
    options.title  = titleMap()[@type]
    options.height = "auto"

    super
    
  # viewAppended:->
  # 
  #   @putList()

  putList:->

    participants = @getData()
    
    # controller = new listControllerMap()[@type]
    # subclass of KDListViewController throws an error !!!
    controller = new KDListViewController
      view            : new KDListView
        subItemClass  : listItemMap()[@type]
    ,
      items           : participants
    
    @addSubView controller.getView(), ".kdmodal-content"

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
  
  click:->
    account = @getData()
    appManager.tell "Members", "createContentDisplay", account
  
  render:->
    return unless @getData()
    {profile} = @getData()
    options = @getOptions()
    host = "#{location.protocol}//#{location.host}/"
    @$().attr "title", options.title or "#{profile.firstName}'s avatar"
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

  click: noop
  
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
      
