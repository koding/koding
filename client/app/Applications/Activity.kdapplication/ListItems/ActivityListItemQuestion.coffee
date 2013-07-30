class QuestionActivityItemView extends KDView
  click: (event) ->
    super
    if $(event.target).is(".activity-item-right-col p")
      @contentDisplayController.emit "ContentDisplayWantsToBeShown", (new ContentDisplayQuestionUpdate {},@getData())


  partial: (activity, account) ->
    data    = @getData()
    unless account
      account =
        profile:
          firstName: 'Loading...'
          lastName: ''

    name = KD.utils.getFullnameFromAccount account

    # log data, "<=- this is data", "∆ ∆ QuestionActivityItemView ∆ ∆"

    partial = $ "<div class='activity-item qanda clearfix'>
                  <span class='avatar'>
                    <a class = 'propagateAccount' href='/#/' style='background-image:url(#{account.profile.avatar});'></a>
                  </span>
                  <div class='activity-item-right-col'>
                    <h3>#{data.questionTitle}</h3>
                    <p class='context'>#{data.questionContent}</p>
                    <footer class='clearfix'>
                      <div><span class='tag'>Q&amp;A</span> by <strong>#{name}</strong> <time class='timeago' datetime='#{new Date(activity.time).format 'isoUtcDateTime'}'></time></div>

                      <div class='commentsContainer'></div>

                      <!--<div class='stats'><cite><span>1456</span> VIEWS</cite> | <cite><span>2</span> ANSWERS</cite> | <cite><span>5</span> COMMENTS</cite></div>-->
                    </footer>
                  </div>
                  </div>
                  "

    partial.find("time.timeago").timeago()
    partial