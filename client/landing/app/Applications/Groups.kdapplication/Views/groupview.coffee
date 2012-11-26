
class GroupView extends JView

  constructor:->
    super
    data = @getData()

    @thumb = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumb.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : "#{KD.apiUri + '/images/default.app.thumb.png'}"

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

  pistachio:->
    """
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{> @thumb}}</a>
      </span>
    </div>
    <section class="right-overflow">
      <h3 class='profilename'>{{#(title)}}<cite></cite></h3>
      <div class="installerbar clearfix">
        <div class="appfollowlike">
          {{> @joinButton}}
        </div>
      </div>
      <div class='profilebio'>
        {p{#(body)}}
      </div>
    </section>
    """
