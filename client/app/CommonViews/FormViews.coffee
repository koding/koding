# FIXME (gokmen) Needs to be rw

class AbstractPersonalFormView extends KDFormView
  constructor:(options, data)->
    memberData = data
    super options, null

    @windowController = @getSingleton 'windowController'
    @setListeners()

    $(window).on "keydown.input",(e)=>
      @checkInput e

  checkInput:(e, classToCheck = 'active')->
    if @$().hasClass(classToCheck) and e.which is 27
      @resetInputValue?()
      @unsetClass 'active'
    else if @$().hasClass(classToCheck) and e.which is 13
      @submit e

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
    @on 'ReceivedClickElsewhere', =>
      @unsetClass 'active'
      @resetInputValue()

  resetInputValue:-> no

class PersonalFormNameView extends AbstractPersonalFormView

  constructor:(options, data)->

    options = $.extend
      cssClass    : 'profilename-form'
      callback    : @formCallback
    , options
    super options, null

    {@memberData} = options
    {profile} = @memberData
    @firstName = new KDInputView
      cssClass      : 'firstname editable'
      defaultValue  : Encoder.htmlDecode profile.firstName
      name          : 'firstName'
      attributes    :
        size        : Encoder.htmlDecode(profile.firstName).length
      validate      :
        rules       :
          required  : yes
          maxLength : 25
        messages    :
          required  : "First name is required!"
          maxLength : "Sorry, maximum 25 chars can be entered for the firstname!"

    @lastName = new KDInputView
      cssClass      : 'lastname editable'
      defaultValue  : Encoder.htmlDecode profile.lastName
      name          : 'lastName'
      attributes    :
        size        : Encoder.htmlDecode(profile.lastName).length
      validate      :
        rules       :
          maxLength : 25
        messages    :
          maxLength : "Sorry, maximum 25 chars can be entered for the lastname!"

    @nameView = new ProfileTextView
      tagName       : "p"
      tooltip       :
        title       : "Click to edit"
        placement   : "left"
        direction   : 'center'
        offset      :
          top       : 0
          left      : -5
    ,@memberData

    @attachListeners()

  pistachio:->
    """
      {{> @nameView}}
      {{> @firstName}}{{> @lastName}}
    """

  resetInputValue:->
    {profile} = @memberData
    @firstName.setValue Encoder.htmlDecode profile.firstName
    @lastName.setValue Encoder.htmlDecode profile.lastName

  attachListeners:->
    @listenTo
      KDEventTypes        : 'keyup'
      listenedToInstance  : @firstName
      callback:(pubInst, events)->
        newWidth = if pubInst.getValue().length < 3 then 3 else if pubInst.getValue().length > 12 then 12 else pubInst.getValue().length
        pubInst.setDomAttributes {size: newWidth}

    @listenTo
      KDEventTypes        : 'keyup'
      listenedToInstance  : @lastName
      callback:(pubInst, events)->
        newWidth = if pubInst.getValue().length < 3 then 3 else if pubInst.getValue().length > 12 then 12 else pubInst.getValue().length
        pubInst.setDomAttributes {size: newWidth}

  formCallback:(formData)->
    {profile} = @memberData
    {firstName, lastName} = formData
    if profile.firstName is firstName and profile.lastName is lastName
      @unsetClass 'active'
      return no

    query =
      'profile.firstName' : firstName
      'profile.lastName'  : lastName

    @memberData.modify query, (err)=>
      if err
        new KDNotificationView
          title : "There was an error updating your profile."
      else
        new KDNotificationView
          title     : "Success!"
          duration  : 500
        @unsetClass 'active'

class PersonalFormAboutView extends AbstractPersonalFormView

  constructor:(options, data)->

    options = $.extend
      cssClass  : 'personal-profile-about'
      callback  : @formCallback
    , options

    super options, null

    {@memberData} = options
    {profile} = @memberData

    @defaultPlaceHolder = "You haven't entered anything in your bio yet. Why not add something now?"

    @aboutInput = new KDInputView
      cssClass      : 'about editable hitenterview active'
      type          : 'textarea'
      defaultValue  : if profile.about is @defaultPlaceHolder then '' else Encoder.htmlDecode profile.about
      placeholder   : if profile.about isnt @defaultPlaceHolder then null else Encoder.htmlDecode profile.about
      name          : 'about'
      validate      :
        rules       :
          required  : yes
          maxLength : 500

    @aboutInfo = new PersonalAboutView
      tooltip            :
        title            : "Click to edit"
        placement        : "left"
        direction        : 'center'
        offset           :
          top            : 0
          left           : -5
      defaultPlaceHolder : @defaultPlaceHolder
    , @memberData

    @windowController = @getSingleton 'windowController'

  pistachio:->
    """
      {{> @aboutInfo}}
      {{> @aboutInput}}
    """

  resetInputValue:->
    {profile} = @memberData
    @aboutInput.setValue if profile.about is @defaultPlaceHolder then '' else Encoder.htmlDecode profile.about

  formCallback:(formData)->
    {profile} = @memberData
    {about} = formData
    if profile.about is about or about is ''
      @unsetClass 'active'
      return no

    changes = 'profile.about' : about
    @memberData.modify changes, (err)=>
      if err
        new KDNotificationView
          title : "There was an error updating your profile."
      else
        @memberData.emit "update"
        new KDNotificationView
          title     : "Success!"
          duration  : 500
        @unsetClass 'active'

class PersonalAboutView extends JView
  constructor:(options, data)->
    super
    {profile} = @getData()
    profile.about or= options.defaultPlaceHolder

  click:(event)->
    $trg = $(event.target)
    more = "span.collapsedtext a.more-link"
    less = "span.collapsedtext a.less-link"
    $trg.parent().addClass("show").removeClass("hide") if $trg.is(more)
    $trg.parent().removeClass("show").addClass("hide") if $trg.is(less)

  pistachio:->
    """
      <p>{{ @utils.applyTextExpansions #(profile.about), yes }}</p>
    """

class PersonalFormLocationView extends AbstractPersonalFormView
  constructor:(options, data)->
    options = $.extend
      cssClass      : 'profilelocation-form'
      callback      : @formCallback
    , options
    super options, data

    {@memberData} = options
    @memberData.locationTags or= []

    @location = new KDInputView
      cssClass      : 'locationtags editable'
      type          : 'text'
      defaultValue  : @memberData.locationTags[0] or 'Earth'
      name          : 'locationTags'
      validate      :
        rules       :
          maxLength : 30

    if @memberData.locationTags.length < 1
      @memberData.locationTags[0] = "Earth"

    @locationTags = new LocationView
      tooltip       :
        title       : "Click to edit"
        placement   : "right"
        direction   : 'center'
        offset      :
          top       : 0
          left      : -5
    ,@memberData

  pistachio:->
    """
      <p>{{> @locationTags}}</p>
      {{> @location}}
    """

  resetInputValue:->
    {profile} = @memberData
    @location.setValue @memberData.locationTags[0] or 'Earth'

  formCallback:(formData)->
    {locationTags} = formData
    if locationTags is @memberData.locationTags[0]
      @unsetClass 'active'
      return no

    if locationTags[0]?
      locationArray = [locationTags]
    else
      locationArray = []

    changes = locationTags : locationArray
    @memberData.modify changes, (err)=>
      if err
        new KDNotificationView
          title : "There was an error updating your profile."
      else
        @memberData.emit "update"
        new KDNotificationView
          title     : "Success!"
          duration  : 500
        @unsetClass 'active'

class LocationView extends JView
  pistachio:->
    """
      {{ @getFirstLocation #(locationTags)}}
    """

  getFirstLocation:(locationTags)->
    locationTags[0]

class PersonalFormSkillTagView extends AbstractPersonalFormView

  constructor:(options, data)->

    options = $.extend
      cssClass  : "kdautocomplete-form"
    , options

    super options, null
    {@memberData} = options
    @memberData.skillTags or= []

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

    tagWrapper.addSubView @loader = new KDLoaderView
      size        :
        width     : 14

    @tagController = new SkillTagAutoCompleteController
      name                : "skillTags"
      cssClass            : 'skilltag-form'
      type                : "tags"
      itemDataPath        : 'title'
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : SkillTagAutoCompletedItem
      outputWrapper       : tagWrapper
      selectedItemsLimit  : 10
      form                : @
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        @propagateEvent KDEventType : "AutoCompleteNeedsTagData", {inputValue,blacklist,callback}

    @tagController.on 'ItemListChanged', =>
      {skillTags}  = @getData()
      @loader.show()
      newTags      = skillTags?.filter((tag)-> tag.$suggest?)
      oldTags      = skillTags?.filter((tag)-> tag.id?)
      plainNewTags = newTags.map((tag)-> tag.$suggest)
      plainOldTags = oldTags.map((tag)-> tag.title)

      joinedTags   = plainNewTags.concat plainOldTags

      @memberData.addTags skillTags, (err)=>
        if err
          log "An error occured:", err
          new KDNotificationView
            title : "There was an error while adding new skills."
        else
          changes = 'skillTags' : joinedTags
          @memberData.modify changes, (err)=>
            if err
              log "An error occured:", err
              new KDNotificationView
                title : "There was an error while updating your profile."
            # else
            #   new KDNotificationView
            #     title     : "Success!"
            #     duration  : 500
            @loader.hide()

    @addSubView @tagController.getView()
    @tagController.putDefaultValues @memberData.skillTags

  mouseDown:(event)->
    no

class SkillTagAutoCompleteController extends KDAutoCompleteController
  constructor:(options, data)->
    options.nothingFoundItemClass or= SuggestNewTagItem
    options.allowNewSuggestions or= yes
    super

  putDefaultValues:(stringTags)->
    KD.remote.api.JTag.some
      title     :
        $in     : stringTags
    ,
      sort      :
        'title' : 1
    , (err,tags)=>
        unless err and not tags
          @setDefaultValue tags
        else
          warn "There was a problem fetching default tags!", err, tags

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
