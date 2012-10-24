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
        contentDisplayController.emit "ContentDisplayWantsToBeHidden",mainView

    topicView = @addTopicView topic

    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass           : ActivityListItemView
      listCssClass        : "activity-related"
      noItemFoundText     : "There is no activity related with <strong>#{topic.title}</strong>."
      limitPerPage        : 5
      filter              :
        content           :
          title           : 'Everything'
          dataSource      : (selector, options, callback)->
            topic.fetchContentTeasers options, (err, teasers)->
              callback err, teasers
        statusupdates     :
          title           : 'Status Updates'
          dataSource      : (selector, options, callback)->
            selector = {targetName: 'JStatusUpdate'}
            topic.fetchContentTeasers options, selector, (err, teasers)->
              callback err, teasers
        codesnippets      :
          title           : 'Code Snippets'
          dataSource      : (selector, options, callback)->
            selector = {targetName: 'JCodeSnip'}
            topic.fetchContentTeasers options, selector, (err, teasers)->
              callback err, teasers
        # Discussions Disabled
        # discussions       :
        #   title           : 'Discussions'
        #   dataSource      : (selector, options, callback)->
        #     selector = {targetName: 'JDiscussion'}
        #     topic.fetchContentTeasers options, selector, (err, teasers)->
        #       callback err, teasers

      sort                :
        'timestamp|new'   :
          title           : 'Latest activity'
          direction       : -1
        'timestamp|old'   :
          title           : 'Most activity'
          direction       : 1
    }, (controller)->
      mainView.addSubView controller.getView()

  addTopicView:(topic)->
    topicContentDisplay = @getView()
    topicContentDisplay.addSubView topicView = new TopicView
      cssClass : "profilearea clearfix"
      delegate : topicContentDisplay
    , topic
    topicView

class TopicView extends KDView

  constructor:(options, data)->

    @followButton = new KDToggleButton
      style           : if data.followee then "kdwhitebtn following-topic" else "kdwhitebtn"
      title           : "Follow"
      dataPath        : "followee"
      defaultState    : if data.followee then "Following" else "Follow"
      loader          :
        color         : "#333333"
        diameter      : 18
        top           : 11
      states          : [
        "Follow", (callback)->
          data.follow (err, response)=>
            data.followee = yes
            @hideLoader()
            unless err
              @setClass 'following-btn following-topic'
              callback? null
        "Following", (callback)->
          data.unfollow (err, response)=>
            data.followee = no
            @hideLoader()
            unless err
              @unsetClass 'following-btn following-topic'
              callback? null
      ]
    , data

    super
    unless data.followee
      KD.whoami().isFollowing? data.getId(), "JTag", (following) =>
        data.followee = following
        if data.followee
          @followButton.setClass 'following-btn following-topic'
          @followButton.setState "Following"
        else
          @followButton.setState "Follow"
          @followButton.unsetClass 'following-btn following-topic'

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{#(image) or "upload an image"}}</a>
      </span>
      {{> @followButton}}
    </div>

    <section>
      <div class="profileinfo">
        {h3{#(title)}}

        <div class="profilestats">
          <div class="posts">
            <a href='#'><cite/>{{@utils.formatPlural #(counts.post), 'Post'}}</a>
          </div>
          <div class="fers">
            <a href='#'><cite/>{{@utils.formatPlural #(counts.followers), 'Follower'}}</a>
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
