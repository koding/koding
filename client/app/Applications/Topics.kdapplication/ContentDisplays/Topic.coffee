class ContentDisplayControllerTopic extends KDViewController

  constructor:(options = {}, data)->

    options.view = mainView = new KDView cssClass : 'topic content-display'

    super options, data

  loadView:(mainView)->
    topic = @getData()

    mainView.addSubView subHeader = new KDCustomHTMLView
      tagName  : "h2"
      cssClass : 'sub-header'

    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)=>
        event.stopPropagation()
        event.preventDefault()
        contentDisplayController = KD.getSingleton "contentDisplayController"
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", mainView

    topicView = @addTopicView topic

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
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
    }, (controller)=>
      @feedController = controller
      mainView.addSubView controller.getView()
      @emit 'ready'

  addTopicView:(topic)->
    topicContentDisplay = @getView()
    topicContentDisplay.addSubView topicView = new TopicView
      cssClass : "profilearea clearfix"
      delegate : topicContentDisplay
    , topic
    topicView

class TopicView extends JView

  constructor:(options, data)->

    @followButton = new FollowButton
      errorMessages  :
        KodingError  : 'Something went wrong while follow'
        AccessDenied : 'You are not allowed to follow topics'
      stateOptions   :
        unfollow     :
          cssClass   : 'following-topic'
      dataType       : 'JTag'
    , data

    super

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
