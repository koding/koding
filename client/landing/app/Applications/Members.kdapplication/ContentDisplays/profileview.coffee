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

    defaultState = if memberData.followee is yes then "Unfollow" else "Follow"

    @followButton = MemberFollowToggleButton
      style      : "kdwhitebtn profilefollowbtn"
    , memberData

    @skillTags = @putSkillTags()

    {nickname} = memberData.profile
    @followers = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        event.preventDefault()
        return if memberData.counts.followers is 0
        KD.getSingleton('router').handleRoute "/#{nickname}/Followers", {state:memberData}
    , memberData

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        event.preventDefault()
        return if memberData.counts.following is 0
        KD.getSingleton('router').handleRoute "/#{nickname}/Following", {state:memberData}
    , memberData

    @likes = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)->
        event.preventDefault()
        return if memberData.counts.following is 0
        KD.getSingleton('router').handleRoute "/#{nickname}/Likes", {state:memberData}
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
        click        : =>
          if KD.checkFlag('exempt', memberData)
            KD.getSingleton('mainController').unmarkUserAsTroll memberData
          else
            KD.getSingleton('mainController').markUserAsTroll memberData

    else
      @trollSwitch = new KDCustomHTMLView

  click: KD.utils.showMoreClickHandler

  putNick:(nick)-> "@#{nick}"

  pistachio:->
    account      = @getData()
    userDomain   = "#{account.profile.nickname}.#{KD.config.userSitesDomain}"
    {nickname}   = account.profile
    amountOfDays = Math.floor (new Date - new Date(account.meta.createdAt)) / (24*60*60*1000)
    name         = KD.utils.getFullnameFromAccount account
    """
    <div class="profileleft">
      <span>
        {{> @avatar}}
      </span>
      {{> @followButton}}
      {cite{ @putNick #(profile.nickname)}}
      {div{#(onlineStatus)}}
    </div>

      {{> @trollSwitch}}

    <section>
      <div class="profileinfo">
        <h3 class="profilename">#{name}</h3>
        <h4 class="profilelocation">{{> @location}}</h4>
        <h5>
          <a class="user-home-link" href="http://#{userDomain}" target="_blank">#{userDomain}</a>

          <cite>member for #{if amountOfDays < 2 then 'a' else amountOfDays} day#{if amountOfDays > 1 then 's' else ''}.</cite>
        </h5>
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

  putSkillTags:->
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

    @sendMessageLink.on "AutoCompleteNeedsMemberData", (pubInst,event)=>
      {callback,inputValue,blacklist} = event
      @fetchAutoCompleteForToField inputValue,blacklist,callback

    @sendMessageLink.on 'MessageShouldBeSent', ({formOutput,callback})=>
      @prepareMessage formOutput, callback

  fetchAutoCompleteForToField:(inputValue,blacklist,callback)->
    KD.remote.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
      callback accounts

  # FIXME: this should be taken to inbox app controller using KD.getSingleton("appManager").tell
  prepareMessage:(formOutput, callback)->
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
