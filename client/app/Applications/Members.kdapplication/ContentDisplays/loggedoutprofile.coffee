class LoggedOutProfile extends KDView
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
        appManager.tell "Members", "createFollowsContentDisplay", memberData, 'followers'
    , memberData

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if memberData.counts.following is 0
        appManager.tell "Members", "createFollowingContentDisplay", memberData, 'followings'
    , memberData

    @sendMessageLink = new MemberMailLink {}, memberData
    
    memberData.locationTags or= []
    if memberData.locationTags.length < 1
      memberData.locationTags[0] = "Earth" 
      
    @location = new LocationView {},memberData
    @setListeners()
    @skillTags = new SkillTagGroup {}, memberData

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
      
  pistachio:->
    """
    <div class="profileleft">
      <span>
        {{> @avatar}}
      </span>
      {{> @followButton}}
    </div>

    <section>
      <div class="profileinfo">
        <h3 class="profilename">{{#(profile.firstName)}} {{#(profile.lastName)}}</h3> 
        <h4 class="profilelocation">{{> @location}}</h4>

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

# get rid of this Sinan - 06/2012
class ContentDisplayControllerVisitor extends ContentDisplayControllerMember
  addProfileView:(member)->
    @getView().addSubView memberProfile = new LoggedInProfile {cssClass : "profilearea clearfix",delegate : @getView()}, member
    memberProfile
