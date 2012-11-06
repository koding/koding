class GroupsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "groups"
    super options,data

    @titleLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : '{{#(title)}}'
      click       : (pubInst, event) => @titleReceivedClick()
    , data

    if options.editable
      @editGroupButton = new KDCustomHTMLView
        tagName     : 'a'
        cssClass    : 'edit-group'
        partial     : '<span class="icon"></span>Group settings'
        click       : (pubInst, event) =>
          @getSingleton('mainController').emit 'EditGroupButtonClicked', @
      , null

      @grantPermissionsButton = new KDCustomHTMLView
        tagName     : 'a'
        cssClass    : 'edit-group'
        partial     : '<span class="icon"></span>Permissions'
        click       : (pubInst, event) =>
          @getSingleton('mainController').emit 'EditPermissionsButtonClicked', @
      , null
    else
      @editButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    @joinButton = new KDToggleButton
      style           : if data.member then "follow-btn following-topic" else "follow-btn"
      title           : "Join"
      dataPath        : "member"
      defaultState    : if data.member then "Leave" else "Join"
      loader          :
        color         : "#333333"
        diameter      : 18
        top           : 11
      states          : [
        "Join", (callback)->
          data.join (err, response)=>
            console.log arguments
            @hideLoader()
            unless err
              @setClass 'following-btn following-topic'
              callback? null
        "Leave", (callback)->
          data.leave (err, response)=>
            console.log arguments
            @hideLoader()
            unless err
              @unsetClass 'following-btn following-topic'
              callback? null
      ]
    , data

  titleReceivedClick:(event)->
    group = @getData()
    appManager.tell "Groups", "createContentDisplay", group

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
          <div class="edit-actions">
          <h4>Edit:</h4>
          <ul>
            {li{> @editGroupButton}}
            {li{> @grantPermissionsButton}}
          </ul>
        </div>
        <div class="button-container">{{> @joinButton}}</div>
      </div>
    </div>
    """

  refreshPartial: ->
    @skillList?.destroy()
    @locationList?.destroy()
    super
    @_addSkillList()
    @_addLocationsList()

  _addSkillList: ->

    @skillList = new ProfileSkillsList {}, {KDDataPath:"Data.skills", KDDataSource: @getData()}
    @addSubView @skillList, '.profile-meta'

  _addLocationsList: ->

    @locationList = new TopicsLocationView {}, @getData().locations
    @addSubView @locationList, '.personal'

class ModalGroupsListItem extends TopicsListItemView

  constructor:(options,data)->

    super options,data

    @titleLink = new TagLinkView {expandable: no}, data

    @titleLink.registerListener
      KDEventTypes  : 'click'
      listener      : @
      callback      : (pubInst, event)=>
        @getDelegate().emit "CloseTopicsModal"

  pistachio:->
    """
    <div class="topictext">
      <div class="topicmeta">
        <div class="button-container">{{> @joinButton}}</div>
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

class GroupsListItemViewEditable extends GroupsListItemView

  constructor:(options = {}, data)->

    options.editable = yes
    options.type     = "topics"

    super options, data
