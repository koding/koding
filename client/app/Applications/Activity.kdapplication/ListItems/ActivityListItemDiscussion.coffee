class DiscussionActivityItemView extends KDView
  viewAppended: ->
    # @setClass 'activity-item clearfix'
    super

  partial: (activity, account) ->
    data    = @getData()
    unless account
      account =
        profile:
          firstName: 'Loading...'
          lastName: ''
      
    # log data, "<=- this is data", "∆ ∆ DiscussionActivityItemView ∆ ∆"

    name = "#{account.profile.firstName} #{account.profile.lastName}"
    partial = $ "<div class='activity-item discussion clearfix'>
                  <span class='avatar'>
                    <a class = 'propagateAccount' href='/#/' style='background-image:url(#{account.profile.avatar});'></a>
                  </span>
                  <div class='activity-item-right-col'>
                    <h3>#{data.title}</h3>
                    <p class='context'>#{data.subTitle} - #{data.body}</p>
                    <footer class='clearfix'>
                      <div><span class='tag'>Discussion</span> by <strong>#{name}</strong> <time class='timeago' datetime='#{new Date(activity.time).format 'isoUtcDateTime'}'></time></div>
                      
                      <div class='commentsContainer'></div>
                      
                      <!--<div class='stats'><cite><span>1456</span> VIEWS</cite> | <cite><span>2</span> ANSWERS</cite> | <cite><span>5</span> COMMENTS</cite></div>-->
                    </footer>
                    
                  </div>
                  </div>
                  "

    partial.find("time.timeago").timeago()
    partial
