class TopicsListItemView extends KDListItemView
  constructor:(options,data)->
    options = options ? {} 
    options.type = "topics"
    options.bind = "mouseenter mouseleave"
    super options,data
    
    @titleLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : '{{#(title)}}'
      click       : (pubInst, event) =>
        @titleReceivedClick()
        event.stopPropagation()
        no
    , data

    @followButton = new KDToggleButton
      style           : if data.followee then "follow-btn following-topic" else "follow-btn"
      title           : "Follow"
      dataPath        : "followee"
      defaultState    : if data.followee then "Following" else "Follow"
      loader          :
        color         : "#333333"
        diameter      : 10
        left          : 2
        top           : 2
      states          : [
        "Follow", (callback)->
          data.follow (err, response)=>
            @hideLoader()
            unless err
              @setClass 'following-btn following-topic'
              callback? null
        "Following", (callback)->
          data.unfollow (err, response)=>
            @hideLoader()
            unless err
              @unsetClass 'following-btn following-topic'
              callback? null
      ]
    , data

  titleReceivedClick:(event)->
    tag = @getData()
    @propagateEvent KDEventType: 'TopicWantsToExpand', tag

  viewAppended:->
    @setClass "topic-item"
    
    @setTemplate @pistachio()
    @template.update()
    
 
  ###
  followTheButton:->
    {profile} = topic = @getData()
    
    @followButton.destroy() if @followButton?
    @followButton = new KDButtonView 
      style : 'follow-btn'
      title : "Follow"
      icon  : no
      callback: =>
        if KD.isLoggedIn()
          topic.followee = yes
          @unfollowTheButton()
          topic.follow (err,res)=>
            if err
              topic.followee = no
              @followTheButton()

    @addSubView @followButton, '.button-container'
  
  unfollowTheButton:()->
    {profile} = topic = @getData()
    
    @followButton.destroy() if @followButton?
    @followButton = new KDButtonView 
      style : 'follow-btn following-btn following-topic'
      title : "Following"
      callback: =>
        topic.followee = no
        if KD.isLoggedIn()
          @followTheButton()
          topic.followee = no
          topic.unfollow (err,res)=>
            if err
              topic.followee = yes
              @unfollowTheButton()
    @addSubView @followButton, '.button-container'
  ###

  setFollowerCount:(count)->
    @$('.followers a').html count

  mouseEnter:->
    # @_mouseenterIntent = setTimeout ()=>
    #   @expandItem()
    # ,500

  mouseLeave:->
    # clearTimeout @_mouseenterIntent if @_mouseenterIntent
    # @collapseItem()
  
  expandItem:->
    return unless @_trimmedBody
    list = @getDelegate()
    $item   = @$()
    $parent = list.$()
    @$clone = $clone = $item.clone()

    pos = $item.position()
    pos.height = $item.outerHeight()
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
            <a href="#">{{#(counts.tagged) or 0}}</a> Posts
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

  # 
  # partial:(data)->
  #   counts = posts : 223, followers : 4234
  #   data.title or= "couldn't fetch..."
  #   data.body or= "couldn't fetch..."
  #   # @_trimmedBody = "#{data.body.slice 0,110}... <i><a href='#'>See more</a></i>" if data.body.length > 110
  #   @_trimmedBody = "#{data.body.slice 0,110}..." if data.body.length > 110
  #   """
  #     <div class="topictext">
  #       <h3><a href="#">#{data.title}</a></h3>
  #       <article>#{@_trimmedBody ? data.body}</article>
  # 
  #       <div class="topicmeta clearfix">
  # 
  #         <div class="topicstats">
  #           <p class="posts">
  #             <span class="icon"></span>
  #             <a href="#">#{counts.posts}</a> Posts
  #           </p>
  #           <p class="followers">
  #             <span class="icon"></span>
  #             <a href="#">#{counts.followers}</a> Followers
  #           </p>
  #         </div>
  #         <div class="button-container"></div> 
  #       </div>
  #     </div>
  #   """
    
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

class ModalTopicsListItem extends TopicsListItemView

  constructor:(options,data)->

    super options,data

    @titleLink = new TagLinkView null, data

    @titleLink.registerListener
      KDEventTypes  : 'click'
      listener      : @
      callback      : (pubInst, event)=>
        @getDelegate().emit "CloseTopicsModal"

  pistachio:->
    """
    <div class="topictext">
      <div class="topicmeta">
        <div class="button-container">{{> @followButton}}</div>
        {{> @titleLink}}
        <div class="stats">
          <p class="posts">
            <span class="icon"></span>{{#(counts.tagged) or 0}} Posts
          </p>
          <p class="fers">
            <span class="icon"></span>{{#(counts.followers) or 0}} Followers
          </p>
        </div>
      </div>
    </div>
    """
