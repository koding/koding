class ContentDisplayControllerMember extends KDViewController
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
        cssClass : 'member content-display'
    ,options
      
    super options, data
  
  loadView:(mainView)->
    member = @getData()

    # mainView.addSubView header = new HeaderViewSection type : "big", title : "Profile"
    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"

    contentDisplayController = @getSingleton "contentDisplayController"
    
    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : ()=>
        contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeHidden",mainView
    
    memberProfile = @addProfileView member
    memberStream = @addActivityView member
    
    memberProfile.on 'FollowButtonClicked', @followAccount
    memberProfile.on 'UnfollowButtonClicked', @unfollowAccount
  
  addProfileView:(member)->
    @getView().addSubView memberProfile = new MemberProfile {cssClass : "profilearea clearfix",delegate : @getView()}, member
    memberProfile
    
  followAccount:(account, callback)->
    account.follow callback
  
  unfollowAccount:(account,callback)->
    account.unfollow callback
    
  addActivityView:(account)->
    

class MemberProfile extends KDView
  constructor:->
    super
    memberData = @getData()
    @avatar = new AvatarStaticView 
      size      :
        width  : 90
        height : 90
    , memberData

    @followButton = new MemberFollowToggleButton
      style           : "kdwhitebtn profilefollowbtn"
      title           : "Follow"
      dataPath        : "followee"
      states          : [
        "Follow", (callback)-> 
          memberData.follow (err, response)=>
            unless err
              @setClass 'following-btn'
              callback? null
        "Unfollow", (callback)->
          memberData.unfollow (err, response)=>
            unless err
              @unsetClass 'following-btn'
              callback? null
      ]
    , memberData

    @skillTags = @putSkillTags()
    
    @followers = new ProfileFollowersView null, memberData
    @following = new ProfileFollowingView null, memberData

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
  

class MemberMailLink extends KDCustomHTMLView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data
    
  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    "<span class='icon'>Contact {{#(profile.firstName)}}</span>"
            
  click:->
    {profile} = member = @getData()
    modal = new KDModalViewWithForms
      title                   : "Compose a message"
      content                 : ""
      cssClass                : "compose-message-modal"
      height                  : "auto"
      width                   : 500
      position                :
        top                     : 300
      overlay                 : yes
      tabs                    :
        navigable             : yes
        callback              : (formOutput)=>
          callback = modal.destroy.bind modal
          @propagateEvent KDEventType : "MessageShouldBeSent", {formOutput,callback}
        forms                 :
          sendForm            :
            fields            :
              to              :
                label         : "Send To:"
                type          : "hidden"
                name          : "recipient"
              subject         :          
                label         : "Subject:"
                placeholder   : 'Enter a subject'
                name          : "subject"
              Message         :          
                label         : "Message:"
                type          : "textarea"
                name          : "body"
                placeholder   : 'Enter your message'
            buttons           :
              Send            :
                title         : "Send"
                style         : "modal-clean-gray"
                type          : "submit"
              Cancel          :
                title         : "cancel"
                style         : "modal-cancel"
                callback      : -> modal.destroy()
    
    toField = modal.modalTabs.forms.sendForm.fields.to
    
    recipientsWrapper = new KDView
      cssClass      : "completed-items"
    
    recipient = new KDAutoCompleteController
      name                : "recipients"
      itemClass           : MemberAutoCompleteItemView
      selectedItemClass   : MemberAutoCompletedItemView
      outputWrapper       : recipientsWrapper
      form                : modal.modalTabs.forms.sendForm
      itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      # defaultValue        : [member]
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in recipient.getSelectedItemData())
        @propagateEvent KDEventType : "AutoCompleteNeedsMemberData", {inputValue,blacklist,callback}

    toField.addSubView recipient.getView()
    toField.addSubView recipientsWrapper
    
    @propagateEvent KDEventType: "NewMessageModalShouldOpen"
    
    recipient.setDefaultValue [member]


class ContentDisplayControllerVisitor extends ContentDisplayControllerMember
  addProfileView:(member)->
    @getView().addSubView memberProfile = new PersonalProfile {cssClass : "profilearea clearfix",delegate : @getView()}, member
    memberProfile


class ProfileFollowersView extends KDView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
      
  pistachio:->
    "{{#(counts.followers)}} <span>Followers</span>"
    
  click:(event)->
    return if @getData().counts.followers is 0
    appManager.tell "Members", "createFollowsContentDisplay", @getData(), 'followers'

class ProfileFollowingView extends KDView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
      
  pistachio:->
    "{{#(counts.following)}} <span>Following</span>"
    
  setFollowingList:([client, followables])->
  click:(event)->
    return if @getData().counts.following is 0
    appManager.tell "Members", "createFollowingContentDisplay", @getData(), 'followings'


