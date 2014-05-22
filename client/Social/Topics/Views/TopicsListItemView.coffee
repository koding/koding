class TopicsListItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.type = "topics"
    super options, data

    data = @getData()
    @titleLink = new JCustomHTMLView
      tagName     : 'a'
      pistachio   : '{{#(title)}}'
      click       : (event) =>
        KD.singletons.router.handleRoute "/Activity?tagged=#{data.slug}"
        KD.utils.stopDOMEvent event
    , data

    if options.editable
      @settingsButton = new KDButtonViewWithMenu
        cssClass   : 'edit-topic transparent'
        icon       : yes
        delegate   : this
        iconClass  : "arrow"
        menu       : @getSettingsMenu()
        callback   : (event) => @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    unless data.status is 'synonym' or data.status is 'deleted'
      @followButton = new FollowButton
        cssClass       : 'solid green'
        errorMessages  :
          KodingError  : 'Something went wrong while follow'
          AccessDenied : 'You are not allowed to follow topics'
        stateOptions   :
          unfollow     :
            cssClass   : 'following-btn'
        dataType       : 'JTag'
      , data
    else
      @followButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    @synonymInfo = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

  getSettingsMenu:->
    {permissions} = KD.config
    canEditTags          = "edit tags" in permissions
    canDeleteTags        = "delete tags" in permissions
    canCreateSynonymTags = "create synonym tags" in permissions
    menu = {}
    mainController = KD.singleton("mainController")
    if canEditTags
      menu["Edit"]       = callback  : => mainController.emit 'TopicItemEditClicked', @
    if canDeleteTags
      menu["Delete"]     = callback  : => mainController.emit 'TopicItemDeleteClicked', @
    if canCreateSynonymTags
      menu["Set Parent"] = callback  : => mainController.emit 'TopicItemSetParentClicked', @
    return menu

  titleReceivedClick:(event)-> @emit 'LinkClicked'

  viewAppended:->
    @setClass "topic-item"
    data = @getData()
    if data.status is "synonym"
      data.fetchSynonym (err, synonym) =>
        return warn "synonym is not valid" if err
        if (synonym)
          data.synonym = synonym
          @addSubView new KDCustomHTMLView
            tagName   : "span"
            cssClass  : "synonym"
            partial   : "Parent: #{data.synonym?.title}"


    @setTemplate @pistachio()
    @template.update()

  setFollowerCount:(count)->
    @$('.followers a').html count

  expandItem:->
    return unless @_trimmedBody
    list = @getDelegate()
    $item   = @$()
    $parent = list.$()
    @$clone = $clone = $item.clone()

    pos = $item.position()
    pos.height = $item.outerHeight(no)
    $clone.addClass "clone"
    $clone.css pos
    $clone.css "background-color" : "white"
    $clone.find('.topictext article').html @getData().body
    $parent.append $clone
    $clone.addClass "expand"
    $clone.on "mouseleave",=>@collapseItem()

  collapseItem:->
    return unless @_trimmedBody
    # @$clone.remove()

  pistachio:->
    body = @getData().body or ""
    """
      {{> @settingsButton}}
      <header>
        {h3{> @titleLink}} <span class="stats">{{#(status) or ''}}</span>
        {{> @synonymInfo}}
      </header>
      <div class="stats">
        <a href="#">{{#(counts.post) or 0}}</a> Posts
        <a href="#">{{#(counts.followers) or 0}}</a> Followers
      </div>
      {article{ #(body) or ""}}
      {{> @followButton}}
    """

class ModalTopicsListItem extends TopicsListItemView

  constructor:(options,data)->

    super options,data

    @titleLink = new TagLinkView
      expandable : no
      click      : => @getDelegate().emit "CloseTopicsModal"
    , data

  pistachio:->
    """
    <div class="topictext">
      <div class="topicmeta">
        <div class="button-container">{{> @followButton}}</div>
        {{> @titleLink}}
        <div class="stats">
          <p class="posts">
            <span class="icon"></span>{{#(counts.post) or 0}} Posts
          </p>
          <p class="fers">
            <span class="icon"></span>{{#(counts.followers) or 0}} Followers
          </p>
        </div>
      </div>
    </div>
    """

class TopicsListItemViewEditable extends TopicsListItemView

  constructor:(options = {}, data)->

    options.editable = yes
    options.type     = "topics"

    super options, data
