class AbstractPersonalFormView extends KDFormView
  constructor:(options, data)->
    memberData = data
    super options, null
    @cancelButton = new KDButtonView
      style : "clean-red"
      title : "Cancel"
      size:
        width : 'auto'
      callback:=>
        @resetInputValue()
        @unsetClass 'active'
        
    @saveButton = new KDButtonView
      style : "cupid-green"
      title : "Save"
      type  : 'submit'
      size:
        width : 'auto'
        
    @windowController = @getSingleton 'windowController'
    @setListeners()
    
  mouseDown:(event)->
    @showForm()
    no

  showForm:->
    @windowController.addLayer @
    if not @$().hasClass 'active'
      @setClass 'active'
      @focusFirstElement()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
    
  pistachio:-> ''

  setListeners:->
    @listenTo 
      KDEventTypes        : "ReceivedClickElsewhere"
      listenedToInstance  : @
      callback:(pubInst, event)->
        @unsetClass 'active'
        @resetInputValue()
        @windowController.removeLayer @
        
  resetInputValue:-> no


class PersonalFormNameView extends AbstractPersonalFormView
  constructor:(options, data)->
    @memberData = data
    
    options = $.extend
      cssClass    : 'profilename-form'
      callback    : @formCallback
    , options
    super options, null

    {profile} = @memberData
    @firstName = new KDInputView
      cssClass      : 'firstname editable'
      defaultValue  : profile.firstName
      name          : 'firstName'
      attributes    :
        size        : profile.firstName.length
      validate      : 
        rules       : 
          required  : yes
        messages    :
          required  : "First name is required!"
    
    @lastName = new KDInputView
      cssClass      : 'lastname editable'
      defaultValue  : profile.lastName
      name          : 'lastName'
      attributes    :
        size        : profile.lastName.length
    
    @nameView = new ProfileTextView
      tagName       : "p"
      tooltip       :
        title       : "Click to edit"
        placement   : "left"
        offset      : 5
    ,@memberData
    
    @attachListeners()
    
    
  pistachio:->
    """
      {{> @nameView}}
      {{> @firstName}}{{> @lastName}}{{> @cancelButton}}{{> @saveButton}}
    """
    
  resetInputValue:->
    {profile} = @memberData
    @firstName.inputSetValue profile.firstName 
    @lastName.inputSetValue profile.lastName 

  attachListeners:->
    @listenTo
      KDEventTypes        : 'keyup'
      listenedToInstance  : @firstName
      callback:(pubInst, events)->
        newWidth = if pubInst.inputGetValue().length < 3 then 3 else if pubInst.inputGetValue().length > 12 then 12 else pubInst.inputGetValue().length
        pubInst.setDomAttributes {size: newWidth}
    
    @listenTo
      KDEventTypes        : 'keyup'
      listenedToInstance  : @lastName
      callback:(pubInst, events)->
        newWidth = if pubInst.inputGetValue().length < 3 then 3 else if pubInst.inputGetValue().length > 12 then 12 else pubInst.inputGetValue().length
        pubInst.setDomAttributes {size: newWidth}
       
  formCallback:(formElements)->
    {profile} = @memberData
    {firstName, lastName} = formElements
    if profile.firstName is firstName and profile.lastName is lastName
      @unsetClass 'active'
      return no
    
    changes = $set:
      'profile.firstName' : firstName
      'profile.lastName'  : lastName
    @memberData.update changes, (err)=>
      if err
        new KDNotificationView
          title : "There was an error updating your profile."
      else 
        new KDNotificationView
          title     : "Success!"
          duration  : 500
        @unsetClass 'active' 

class PersonalFormAboutWrapperView extends KDView
  constructor:(options, data)->
    options = $.extend
      cssClass    : 'personal-profile-about'
      tooltip     :
        title     : "Click to edit"
        selector  : "p"
        placement : "left"
        offset    : 5
    , options
    super options, data
    {profile} = @getData()
    profile.about or= "You haven't entered anything in your bio yet. Why not add something now?"
    
    @formView = new PersonalFormAboutView {}, @getData()
    
    @windowController = @getSingleton 'windowController'
    @listenTo 
      KDEventTypes        : "ReceivedClickElsewhere"
      listenedToInstance  : @
      callback:(pubInst, event)->
        @unsetClass 'active'
        @formView.resetInputValue()
        @windowController.removeLayer @

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <p>{{ @utils.applyTextExpansions #(profile.about)}}</p>
      {{> @formView}}
    """
    
  mouseDown:(event)->
    @windowController.addLayer @
    if not @$().hasClass 'active'
      @setClass 'active'
      @formView.focusFirstElement()


class PersonalFormAboutView extends AbstractPersonalFormView
  constructor:(options, data)->
    @memberData = data
    
    options = $.extend
      cssClass  : 'profileabout-form'
      callback  : @formCallback
    , options

    super options, null
    
    {profile} = @memberData
    
    @aboutInput = new KDInputView
      cssClass      : 'about editable'
      type          : 'textarea'
      defaultValue  : if profile.about is "You haven't entered anything in your bio yet. Why not add something now?" then '' else Encoder.htmlDecode profile.about
      placeholder   : if profile.about isnt "You haven't entered anything in your bio yet. Why not add something now?" then null else Encoder.htmlDecode profile.about
      name          : 'about'

    @cancelButton = new KDButtonView
      style : "clean-red"
      title : "Cancel"
      size:
        width : 'auto'
      callback:=>
        @resetInputValue()
        @parent.unsetClass 'active'
    
  pistachio:->
    """
      {{> @aboutInput}}{{> @cancelButton}}{{> @saveButton}}
    """

  resetInputValue:->
    {profile} = @memberData
    @aboutInput.inputSetValue if profile.about is "You haven't entered anything in your bio yet. Why not add something now?" then '' else Encoder.htmlDecode profile.about

  formCallback:(formElements)->
    {profile} = @memberData
    {about} = formElements
    if profile.about is about
      @parent.unsetClass 'active'
      return no
    
    changes = $set:
      'profile.about'  : about
    @memberData.update changes, (err)=>
      if err
        new KDNotificationView
          title : "There was an error updating your profile."
      else 
        new KDNotificationView
          title     : "Success!"
          duration  : 500
        @parent.unsetClass 'active'
        
  mouseDown:-> no


class PersonalFormLocationView extends AbstractPersonalFormView
  constructor:(options, data)->
    @memberData = data
    options = $.extend
      cssClass      : 'profilelocation-form'
      callback      : @formCallback 
    , options
    super options, data
    
    @memberData.locationTags or= []
    
    @location = new KDInputView
      cssClass      : 'locationtags editable'
      type          : 'text'
      defaultValue  : @memberData.locationTags[0] or 'Earth'
      name          : 'locationTags'
    
    if @memberData.locationTags.length < 1
      @memberData.locationTags[0] = "Earth"  
    
    @locationTags = new LocationView
      tooltip       :
        title       : "Click to edit"
        placement   : "right"
        offset      : 5
    ,@memberData
      
  pistachio:->
    """
      <p>{{> @locationTags}}</p>
      {{> @location}}{{> @cancelButton}}{{> @saveButton}}
    """
    
  resetInputValue:->
    {profile} = @memberData
    @location.inputSetValue @memberData.locationTags[0] or 'Earth' 

  formCallback:(formElements)->
    {locationTags} = formElements
    if locationTags is @memberData.locationTags[0]
      @unsetClass 'active'
      return no
    
    if locationTags[0]?
      locationArray = [locationTags]
    else
      locationArray = []
    
    changes = $set:
      'locationTags' : locationArray
    @memberData.update changes, (err)=>
      if err
        new KDNotificationView
          title : "There was an error updating your profile."
      else 
        new KDNotificationView
          title     : "Success!"
          duration  : 500
        @unsetClass 'active'

class LocationView extends KDCustomHTMLView
  constructor:(options, data)->
    super

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      {{ @getFirstLocation #(locationTags)}}
    """

  getFirstLocation:(locationTags)->
    locationTags[0]


class PersonalFormSkillTagView extends KDFormView
  constructor:(options, data)->
    @memberData = data # bc we have a conflict on KDFormView::getData()
    options = $.extend
      cssClass  : "kdautocomplete-form"
    , options

    super options, null

    @memberData.skillTags or= []
    
    @formSetCallback (formElements)=>
      tagIds = formElements.skillTags.map((tag)-> tag.getId?() or $suggest: tag)
      @memberData.addTags 'skillTags', tagIds, (err)-> debugger

  showForm:->
    unless @$().hasClass "active"
      @label.updatePartial "SKILLS"
      @setClass 'active'
      @focusFirstElement()
    
  hideForm:->
    @unsetClass 'active'

  viewAppended:->
    super

    @addSubView tagWrapper = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "form-actions-holder clearfix"
      bind        : "mouseenter mouseleave"
      mouseenter  : =>
        unless @$().hasClass "active"
          @label.updatePartial "<a href='#'>Click to edit...</a>"
      mouseleave  : =>
        @label.updatePartial "SKILLS"

    tagWrapper.addSubView @label = new KDLabelView
      cssClass    : "skilltagslabel"
      title       : "SKILLS"
      click       : (pubInst, event)=> @showForm()

    tagController = new SkillTagAutoCompleteController
      name                : "skillTags"
      cssClass            : 'skilltag-form'
      type                : "tags"
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : SkillTagAutoCompletedItem
      outputWrapper       : tagWrapper
      selectedItemsLimit  : 10
      form                : @
      itemDataPath        : "title"
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in tagController.getSelectedItemData() when 'function' is typeof data.getId)
        @propagateEvent KDEventType : "AutoCompleteNeedsTagData", {inputValue,blacklist,callback}

    @addSubView tagController.getView()
    tagController.putDefaultValues @memberData.skillTags

    @addSubView buttonWrapper = new KDCustomHTMLView
      tagName     : 'div'
      cssClass    : 'button-container'
      partial     : ''

    buttonWrapper.addSubView cancelButton = new KDButtonView
      style     : "clean-red"
      title     : "Cancel"
      size      :
        width   : 'auto'
      callback  : => @hideForm()

    buttonWrapper.addSubView saveButton = new KDButtonView
      style     : "cupid-green"
      title     : "Save"
      type      : 'submit'
      size      :
        width   : 'auto'
        
class SkillTagAutoCompleteController extends KDAutoCompleteController
  constructor:(options, data)->
    options.nothingFoundItemClass or= SuggestNewTagItem
    options.allowNewSuggestions or= yes
    super
  
  putDefaultValues:(stringTags)->
    bongo.api.JTag.some
      title     :
        $in     : stringTags
    ,
      sort      : 
        'title' : 1
    , (err,tags)=>
        unless err and not tags
          @setDefaultValue tags
        else
          warn "there was a problem fetching default tags!", err, tags
    

  
class SkillTagAutoCompletedItem extends KDAutoCompletedItem
  constructor:(options, data)->
    options.cssClass = "clearfix"
    super
    @tag = new TagLinkView {},data

  pistachio:->"{{> @tag}}"

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
    
  click:(event)->
    @getDelegate().removeFromSubmitQueue @ if $(event.target).is('span.close-icon')
    @getDelegate().getView().$input().trigger


  
class PersonalFormAvatarView extends AbstractPersonalFormView
  constructor:(options, data)->
    @memberData = data
    options = $.extend
      cssClass      : 'profileavatar-form'
      callback      : @formCallback 
    , options
    super options, null
    @avatarImg = new AvatarSwapView 
      size:
        width: 90
        height: 90
    , @memberData

    @cancelButton = new KDButtonView
      style : "clean-red"
      title : "Cancel"
      size:
        width : 'auto'
      callback:=>
        @unsetClass 'active'
        @avatarImg.swapAvatarView.destroy()
    
  pistachio:->
    """
      {{> @avatarImg}}{{> @cancelButton}}{{> @saveButton}}
    """

  setListeners:->
    @listenTo 
      KDEventTypes        : "ReceivedClickElsewhere"
      listenedToInstance  : @
      callback:(pubInst, event)->
        @avatarImg.swapAvatarView.destroy()
        @unsetClass 'active'
        @windowController.removeLayer @

    @listenTo
      KDEventTypes        : 'DragEnterOnWindow'
      listenedToInstance  : @windowController
      callback:(pubInst, event)->
        if not @$().hasClass 'active'
          @windowController.addLayer @
          @setClass 'active' 
          @avatarImg.setFileUpload()

    @listenTo
      KDEventTypes        : 'DragExitOnWindow'
      listenedToInstance  : @windowController
      callback:(pubInst, event)->
        @avatarImg.swapAvatarView.destroy()
        @unsetClass 'active'
        @windowController.removeLayer @
      
  mouseDown:(event)->
    @windowController.addLayer @
    if not @$().hasClass 'active'
      @setClass 'active' 
    @avatarImg.setFileUpload()
    
  formCallback:(formElements)->

   