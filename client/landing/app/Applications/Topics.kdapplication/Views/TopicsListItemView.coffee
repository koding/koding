class TopicsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "topics"
    super options,data

    @titleLink = new KDCustomHTMLView
      tagName     : 'a'
      pistachio   : '{{#(title)}}'
      click       : (event) =>
        event?.stopPropagation()
        event?.preventDefault()
        @titleReceivedClick()
        no
    , data

    if options.editable
      @editButton = new KDCustomHTMLView
        tagName     : 'a'
        cssClass    : 'edit-topic'
        pistachio   : '<span class="icon"></span>Edit'
        click       : (event) =>
          KD.getSingleton('mainController').emit 'TopicItemEditLinkClicked', @
      , null
    else
      @editButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    @followButton = new FollowButton {cssClass: 'topic'}, data

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
    <div class="topictext">
      {{> @editButton}}
      {h3{> @titleLink}}
      {article{#(body)}}
      <div class="topicmeta clearfix">
        <div class="topicstats">
          <p class="posts">
            <span class="icon"></span>
            <a href="#">{{#(counts.post) or 0}}</a> Posts
          </p>
          <p class="followers">
            <span class="icon"></span>
            <a href="#">{{#(counts.followers) or 0}}</a> Followers
          </p>
        </div>
        <div class="button-container">{{> @followButton}}</div>
      </div>
    </div>
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
