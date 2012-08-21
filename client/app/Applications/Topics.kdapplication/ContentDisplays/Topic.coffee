class ContentDisplayControllerTopic extends KDViewController
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
        cssClass : 'topic content-display'
    ,options

    super options, data

  loadView:(mainView)->
    topic = @getData()

    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"

    contentDisplayController = @getSingleton "contentDisplayController"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : ()=>
        contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeHidden",mainView

    topicView = @addTopicView topic

    topicView.on 'FollowButtonClicked', @followAccount
    topicView.on 'UnfollowButtonClicked', @unfollowAccount

    appManager.tell 'Feeder', 'createContentFeedController', {
      subItemClass        : ActivityListItemView
      listCssClass        : "activity-related"
      limitPerPage        : 5
      filter              :
        content           :
          title           : 'All content'
          dataSource      : (selector, options, callback)->
            topic.fetchContentTeasers (err, teasers)->
              callback err, teasers
        codeshares        :
          title           : 'Code shares'
          dataSource      : -> log 'just code shares'
        developers        :
          title           : 'Developers'
          dataSource      : -> log 'just developers'
      sort                :
        'meta.modifiedAt' :
          title           : 'Latest activity'
          direction       : -1
    }, (controller)->
      mainView.addSubView controller.getView()

  addTopicView:(topic)->
    topicContentDisplay = @getView()
    topicContentDisplay.addSubView topicView = new TopicView
      cssClass : "profilearea clearfix"
      delegate : topicContentDisplay
    , topic
    topicView

  followAccount:(topic, callback)->
    topic.follow callback

  unfollowAccount:(topic,callback)->
    topic.unfollow callback

class TopicView extends KDView
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    topic = @getData()

    if topic.followee
      @unfollowTheButton()
    else
      @followTheButton()

  followTheButton:->
    {profile, counts} = topic = @getData()

    @followButton.destroy() if @followButton?
    @followButton = new KDButtonView
      style : 'kdwhitebtn profilefollowbtn'
      title : "Follow"
      callback: =>
        topic.followee = yes
        @unfollowTheButton()
        @emit 'FollowButtonClicked', topic, (err, followerCount)=>
          if err
            warn err
            topic.followee = no
            @followTheButton()
          else
            @setFollowCounts followerCount, counts.following
    @addSubView @followButton, '.profileleft'

  unfollowTheButton:()->
    {profile, counts} = topic = @getData()

    @followButton.destroy() if @followButton?
    @followButton = new KDButtonView
      style : 'kdwhitebtn profilefollowbtn following-btn'
      title : "Following"
      callback: =>
        topic.followee = no
        @followTheButton()
        @emit 'UnfollowButtonClicked', topic, (err, followerCount)=>
          if err
            warn err
            topic.followee = yes
            @unfollowTheButton()
          else
            @setFollowCounts followerCount, counts.following
    @addSubView @followButton, '.profileleft'

  setFollowCounts:(followerCount, followingCount)->
    @$('.fers a').html followerCount
    @$('.fing a').html followingCount

  pistachio:->
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{#(image) or "upload an image"}}</a>
      </span>
    </div>

    <section>
      <div class="profileinfo">
        {h3{#(title)}}

        <div class="profilestats">
          <div class="posts">
            {{@utils.formatPlural #(counts.post), 'Post'}}
          </div>
          <div class="fers">
            <a href='#'>{{@utils.formatPlural #(counts.followers), 'Follower'}}</a>
          </div>
        </div>
      </div>

      <div class='profilebio'>
        {p{#(body)}}
      </div>

      <div class="skilltags">
      </div>

    </section>
    """
