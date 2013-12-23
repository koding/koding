class TopicsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "topics"
    super options, data

    data = @getData()
    @titleLink = new KDCustomHTMLView
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


  getSettingsMenu:->
    menu = {}
    menu["Edit"] =
      callback  : => KD.getSingleton('mainController').emit 'TopicItemEditClicked', @
    menu["Delete"] =
      callback : => KD.getSingleton('mainController').emit 'TopicItemDeleteClicked', @
    menu["Set Synonym"] =
      callback : => KD.getSingleton('mainController').emit 'TopicItemSynonymClicked', @

    menu

  titleReceivedClick:(event)-> @emit 'LinkClicked'

  viewAppended:->
    @setClass "topic-item"

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
    """
      {{> @settingsButton}}
      <header>
        {h3{> @titleLink}} <span class="stats">{{#(status) or ''}}</span>
      </header>
      <div class="stats">
        <a href="#">{{#(counts.post) or 0}}</a> Posts
        <a href="#">{{#(counts.followers) or 0}}</a> Followers
      </div>
      {article{ #(body)}}
      {{> @followButton}}
    """

    # """
    # <div class="topictext">
    #   {{> @editButton}}
    #   {h3{> @titleLink}}
    #   {article{#(body)}}
    #   <div class="topicmeta clearfix">
    #     <div class="topicstats">
    #       <p class="posts">
    #         <span class="icon"></span>
    #         <a href="#">{{#(counts.post) or 0}}</a> Posts
    #       </p>
    #       <p class="followers">
    #         <span class="icon"></span>
    #         <a href="#">{{#(counts.followers) or 0}}</a> Followers
    #       </p>
    #     </div>
    #     <div class="button-container">{{> @followButton}}</div>
    #   </div>
    # </div>
    # """

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
