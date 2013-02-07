
class GroupView extends ActivityContentDisplay

  constructor:->
    super
    data = @getData()

    @setClass 'group-header'

    @thumb = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : =>
        @thumb.$().attr "src", "/images/default.app.thumb.png"
      attributes  :
        src       : @getData().avatar or "http://lorempixel.com/#{100+@utils.getRandomNumber(10)}/#{100+@utils.getRandomNumber(10)}"
        # src       : "#{KD.apiUri + '/images/default.app.thumb.png'}"

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


    @joinButton.on 'Joined', =>
      @enterLink.show()

    @joinButton.on 'Left', =>
      @enterLink.hide()

    {slug, privacy} = @getData()

    @enterLink = new CustomLinkView
      cssClass  : 'enter-group'
      href      : "/#{slug}/Activity"
      target    : slug
      title     : 'Open group'
      click     : if privacy is 'private' then @bound 'privateGroupOpenHandler'

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
    <div class="profileleft">
      <span>
        <a class='profile-avatar' href='#'>{{> @thumb}}</a>
      </span>
    </div>
    <section class="right-overflow">
      <h3 class='profilename'>{{#(title)}}<cite></cite></h3>
      <div class='profilebio'>
        {p{#(body)}}
      </div>
      <div class="installerbar clearfix">
        <div class="appfollowlike">
          {{> @enterLink}}
          {{> @joinButton}}
        </div>
      </div>
    </section>
    """
