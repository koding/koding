class ProfileView extends KDView
  constructor:->
    super
    memberData = @getData()
    @avatar = new AvatarStaticView
      size      :
        width  : 90
        height : 90
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
      pistachio   : "{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        return if memberData.counts.followers is 0
        appManager.tell "Members", "createFolloweeContentDisplay", memberData, 'followers'
    , memberData

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if memberData.counts.following is 0
        appManager.tell "Members", "createFolloweeContentDisplay", memberData, 'following'
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

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

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
          <div class='contact'>
            {{> @sendMessageLink}}
          </div>
        </div>

        <div class="profilebio">
          <p>{{ @utils.applyTextExpansions #(profile.about)}}</p>
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
    bongo.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
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
    bongo.api.JPrivateMessage.create messageDetails, callback
