class GroupView extends ActivityContentDisplay

  constructor:->

    super

    data = @getData()

    @thumb = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumb.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : @getData().avatar or "http://lorempixel.com/60/60/?#{@utils.getRandomNumber()}}"

    @joinButton = new JoinButton
      style           : if data.member then "join follow-btn following-topic" else "join follow-btn"
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
              @emit 'Joined'
              @setClass 'following-btn following-topic'
              callback? null
        "Leave", (callback)->
          data.leave (err, response)=>
            console.log arguments
            @hideLoader()
            unless err
              @emit 'Left'
              @unsetClass 'following-btn following-topic'
              callback? null
      ]
    , data

    {slug, privacy} = data

    @enterLink = new CustomLinkView
      cssClass  : 'enter-group'
      href      : "/#{slug}/Activity"
      target    : slug
      title     : 'Open group'
      click     : if privacy is 'private' then @bound 'privateGroupOpenHandler'

    @readme = new GroupReadmeView {}, data

    @joinButton.on 'Joined', @enterLink.bound "show"

    @joinButton.on 'Left', @enterLink.bound "hide"

    {JGroup} = KD.remote.api

    JGroup.fetchMyMemberships data.getId(), (err, groups)=>
      if err then error err
      else
        if data.getId() in groups
          @joinButton.setState 'Leave'
          @joinButton.redecorateState()
          # @enterButton.show()
    # @homeLink = new KDCustomHTMLView
    #   tagName     : 'a'
    #   attributes  :
    #     href      : data.slug
    #   pistachio   : "Enter {{#(title)}}"
    #   click       : (event)->
    #     # debugger
    #     event.stopPropagation()
    #     event.preventDefault()
    #     KD.getSingleton('router').handleRoute "/#{data.slug}/Activity"
    # , data

  privateGroupOpenHandler: GroupsAppController.privateGroupOpenHandler

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <h2 class="sub-header">{{> @back}}</h2>
    <div class='group-header'>
      <div class='avatar'>
        <span>{{> @thumb}}</span>
      </div>
      <section class="right-overflow">
        {h2{#(title)}}
        <div class="buttons">
          {{> @enterLink}}
          {{> @joinButton}}
        </div>
      </section>
      <div class="navbar clearfix">
      </div>
      <div class='desc'>
        {p{#(body)}}
      </div>
    </div>
    {{> @readme}}
    """
