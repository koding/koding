class LinkActivityItemView extends KDView
  click:->
    super
    if $(event.target).is(".activity-item-right-col")
      @contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeShown",new ContentDisplayLink {},@getData()
      
      
  partial: (activity, account) ->
    data    = @getData()
    unless account
      account =
        profile:
          firstName: 'Loading...'
          lastName: ''
    
    # log data, "<=- this is data", "∆ ∆ LinkActivityItemView ∆ ∆"

    name = "#{account.profile.firstName} #{account.profile.lastName}"
    host = "http://#{location.host}/"
    fallbackUrl = "url(http://www.gravatar.com/avatar/#{profile.hash}?size=40&d=#{encodeURIComponent(host + '/images/defaultavatar/default.avatar.40.png')})"
    partial = $ "<div class='activity-item link clearfix'>
                  <span class='avatar'>
                    <a class = 'propagateAccount' href='/#/' style='background-image:#{fallbackUrl};'></a>
                  </span>
                  <div class='activity-item-right-col'>
                    <h3><a href='#{data.body}' target='_blank'>#{data.link}</a></h3>
                    <p class='context'>#{data.body}</p>
                    <footer class='clearfix'>
                      <div><span class='tag'>Link</span> by <strong>#{name}</strong> <time class='timeago' datetime='#{new Date(activity.time).format 'isoUtcDateTime'}'></time></div>
                      <div class='commentsContainer'></div>
                      <!--<div class='stats'><cite><span>1456</span> VIEWS</cite> | <cite><span>2</span> ANSWERS</cite> | <cite><span>5</span> COMMENTS</cite></div>-->
                    </footer>
                    
                  </div>
                  </div>
                  "

    partial.find("time.timeago").timeago()
    partial
