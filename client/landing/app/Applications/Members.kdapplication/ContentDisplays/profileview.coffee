class ProfileView extends JView
  constructor:->

    super

    memberData = @getData()

    @avatar = new AvatarStaticView
      size     :
        width  : 90
        height : 90
      click    : =>
        pos =
          top  : @avatar.getBounds().y - 8
          left : @avatar.getBounds().x - 8
        modal = new KDModalView
          # title   : "#{memberData.profile.firstName} #{memberData.profile.lastName}"
          width    : 400
          fx       : yes
          overlay  : yes
          draggable: yes
          position : pos
        modal.addSubView new AvatarStaticView
          size     :
            width  : 400
            height : 400
        , memberData
    , memberData

    defaultState  = if memberData.followee then "Unfollow" else "Follow"

    @followButton = new MemberFollowToggleButton
      style           : "kdwhitebtn profilefollowbtn"
      title           : "Follow"
      dataPath        : "followee"
      defaultState    : defaultState
      loader          :
        color         : "#333333"
        diameter      : 18
        # left          : 3
      states          : [
        "Follow", (callback)->
          memberData.follow (err, response)=>
            @hideLoader()
            unless err
              @setClass 'following-btn'
              callback? null
        "Unfollow", (callback)->
          memberData.unfollow (err, response)=>
            @hideLoader()
            unless err
              @unsetClass 'following-btn'
              callback? null
      ]
    , memberData

    @skillTags = @putSkillTags()

    @followers = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        return if memberData.counts.followers is 0
        appManager.tell "Members", "createFolloweeContentDisplay", memberData, 'followers'
    , memberData

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if memberData.counts.following is 0
        appManager.tell "Members", "createFolloweeContentDisplay", memberData, 'following'
    , memberData

    @likes = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)->
        return if memberData.counts.following is 0
        appManager.tell "Members", "createLikedContentDisplay", memberData
    , memberData

    @sendMessageLink = new MemberMailLink {}, memberData

    memberData.locationTags or= []
    if memberData.locationTags.length < 1
      memberData.locationTags[0] = "Earth"

    @location = new LocationView {},memberData
    @setListeners()
    @skillTags = new SkillTagGroup {}, memberData

    if KD.checkFlag 'super-admin'

      @trollSwitch = new KDCustomHTMLView
        tagName      : "a"
        partial      : if KD.checkFlag('exempt', memberData) then 'Unmark Troll' else 'Mark as Troll'
        cssClass     : "troll-switch"
        click        :() =>
          if KD.checkFlag('exempt', memberData)
            @getSingleton('mainController').unmarkUserAsTroll memberData
          else
            @getSingleton('mainController').markUserAsTroll memberData

    else
      @trollSwitch = new KDCustomHTMLView

  click:(event)->

    $trg = $(event.target)
    more = "span.collapsedtext a.more-link"
    less = "span.collapsedtext a.less-link"
    $trg.parent().addClass("show").removeClass("hide") if $trg.is(more)
    $trg.parent().removeClass("show").addClass("hide") if $trg.is(less)

  putNick:(nick)-> "@#{nick}"

  pistachio:->
    userDomain = "#{@getData().profile.nickname}.koding.com"
    """
    <div class="profileleft">
      <span>
        {{> @avatar}}
      </span>
      {{> @followButton}}
      {cite{ @putNick #(profile.nickname)}}
    </div>

      {{> @trollSwitch}}

    <section>
      <div class="profileinfo">
        <h3 class="profilename">{{#(profile.firstName)}} {{#(profile.lastName)}}</h3>
        <h4 class="profilelocation">{{> @location}}</h4>
        <h5><span class='icon fl'></span><a class="user-home-link right-overflow" href="http://#{userDomain}" target="_blank">#{userDomain}</a></h5>
        <div class="profilestats">
          <div class="fers">
            {{> @followers}}
          </div>
          <div class="fing">
            {{> @following}}
          </div>
           <div class="liks">
            {{> @likes}}
          </div>
          <div class='contact'>
            {{> @sendMessageLink}}
          </div>
        </div>

        <div class="profilebio">
          <p>{{ @utils.applyTextExpansions #(profile.about), yes}}</p>
        </div>

        <div class="skilltags"><label>SKILLS</label>{{> @skillTags}}</div>
      </div>
    </section>

    """

  putSkillTags:()->
    memberData = @getData()

    memberData.skillTags or= ['No Tags']
    skillTagHTML = "<label>Skills</label>"
    for skillTag in memberData.skillTags
      if skillTag = 'No Tags'
        skillTagHTML += '<p>No Tags Yet. Add One.</p>'
      else
        skillTagHTML += "<span>#{skillTag}</span>"

    skillTagHTML

  setListeners:->
    @sendMessageLink.registerListener
      KDEventTypes : "ToFieldHasNewInput"
      listener     : @
      callback     : (pubInst, data)->
        return if data.disabledForBeta
        {type,action} = data
        mainView.showTab type
        if action is "change-tab"
          mainView.showTab data.type
        else
          mainView.sort data.type

    @sendMessageLink.registerListener
      KDEventTypes  : "AutoCompleteNeedsMemberData"
      listener      : @
      callback      : (pubInst,event)=>
        {callback,inputValue,blacklist} = event
        @fetchAutoCompleteForToField inputValue,blacklist,callback

    @sendMessageLink.registerListener
      KDEventTypes  : 'MessageShouldBeSent'
      listener      : @
      callback      : (pubInst,{formOutput,callback})->
        @prepareMessage formOutput,callback

  fetchAutoCompleteForToField:(inputValue,blacklist,callback)->
    KD.remote.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
      callback accounts

  prepareMessage:(formOutput, callback)=>
    {body, subject, recipients} = formOutput
    to = recipients.join ' '

    @sendMessage {to, body, subject}, (err, message)->
      new KDNotificationView
        title     : if err then "Failure!" else "Success!"
        duration  : 1000
      message.mark 'read'
      callback? err, message

  sendMessage:(messageDetails, callback)->
    KD.remote.api.JPrivateMessage.create messageDetails, callback
