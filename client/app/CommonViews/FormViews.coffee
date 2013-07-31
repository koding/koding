# FIXME (gokmen) Needs to be rw

class AbstractPersonalFormView extends KDFormView
  constructor:(options = {}, data)->
    super options, null
    @memberData = data

    @windowController = KD.getSingleton 'windowController'
    @setListeners()

    $(window).on "keydown.input", @checkInput.bind this

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

  viewAppended:    JView::viewAppended
  pistachio:       -> ''
  resetInputValue: -> no

  setListeners:->
    @on 'ReceivedClickElsewhere', =>
      @unsetClass 'active'
      @resetInputValue()

  doModify:(modifier, unsetClass=yes, callback=noop)->
    @memberData.modify modifier, (err)=>
      if err
        KD.notify_ 'There was an error updating your profile.'
        return callback err
      @memberData.emit 'update'
      @unsetClass 'active'  if unsetClass
      callback null


class PersonalFormNameView extends AbstractPersonalFormView

  constructor:(options = {}, data)->
    options = $.extend
      cssClass    : 'profilename-form'
      callback    : @formCallback
    , options

    super options, data

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
    , @memberData

    @attachListeners()

  pistachio:->
    """
    {{> @nameView}}
    {{> @firstName}}{{> @lastName}}
    """

  resetInputValue:->
    @firstName.setValue Encoder.htmlDecode @memberData.profile.firstName
    @lastName.setValue  Encoder.htmlDecode @memberData.profile.lastName

  attachListeners:->
    @firstName.on 'keyup', (event)=>
      pubInst = @firstName
      newWidth = if pubInst.getValue().length < 3 then 3 else if pubInst.getValue().length > 12 then 12 else pubInst.getValue().length
      pubInst.setDomAttributes {size: newWidth}

    @lastName.on 'keyup', (events)->
      pubInst = @lastName
      newWidth = if pubInst.getValue().length < 3 then 3 else if pubInst.getValue().length > 12 then 12 else pubInst.getValue().length
      pubInst.setDomAttributes {size: newWidth}

  formCallback:({firstName, lastName})->
    {profile} = @memberData
    if profile.firstName is firstName and profile.lastName is lastName
      @unsetClass 'active'
      return no

    @doModify
      'profile.firstName' : firstName
      'profile.lastName'  : lastName


class PersonalFormAboutView extends AbstractPersonalFormView

  constructor:(options = {}, data)->
    options = $.extend
      cssClass  : 'personal-profile-about'
      callback  : @formCallback
    , options

    super options, data

    {profile}  = @memberData

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

    @windowController = KD.getSingleton 'windowController'

  pistachio:->
    """
    {{> @aboutInfo}}
    {{> @aboutInput}}
    """

  resetInputValue:->
    {profile} = @memberData
    if profile.about is @defaultPlaceHolder
      @aboutInput.setValue ''
    else
      @aboutInput.setValue Encoder.htmlDecode profile.about

  formCallback:({about})->
    if @memberData.profile.about is about
      @unsetClass 'active'
      return no

    @doModify 'profile.about' : about


class PersonalAboutView extends JView
  constructor:(options, data)->
    super options, data
    @getData().profile.about or= options.defaultPlaceHolder

  click: KD.utils.showMoreClickHandler

  pistachio:->
    """
    <p>{{ @utils.applyTextExpansions #(profile.about), yes }}</p>
    """


class PersonalFormLocationView extends AbstractPersonalFormView

  constructor:(options = {}, data)->
    options = $.extend
      cssClass      : 'profilelocation-form'
      callback      : @formCallback
    , options

    super options, data

    @memberData.locationTags or= ['Earth']

    @location     = new KDInputView
      cssClass      : 'locationtags editable'
      type          : 'text'
      defaultValue  : @memberData.locationTags[0]
      name          : 'locationTags'
      validate      :
        rules       :
          maxLength : 30

    @locationTags = new LocationView
      tooltip       :
        title       : "Click to edit"
        placement   : "right"
        direction   : 'center'
        offset      :
          top       : 0
          left      : -5
    , @memberData

  pistachio:->
    """
    <p>{{> @locationTags}}</p>
    {{> @location}}
    """

  resetInputValue:->
    @location.setValue @memberData.locationTags[0] or 'Earth'

  formCallback:({locationTags})->
    if locationTags is @memberData.locationTags[0]
      @unsetClass 'active'
      return no

    @doModify {locationTags: [locationTags]}


class LocationView extends JView

  pistachio:-> "{{ @getFirstLocation #(locationTags)}}"
  getFirstLocation:(locationTags)-> locationTags[0]


class PersonalFormSkillTagView extends AbstractPersonalFormView

  constructor:(options = {}, data)->
    options = $.extend
      cssClass : "kdautocomplete-form"
    , options

    super options, data

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
      click       : @bound 'showForm'

    tagWrapper.addSubView @loader = new KDLoaderView size : width : 14

    @tagController = new SkillTagAutoCompleteController
      name                : 'skillTagsInput'
      cssClass            : 'skilltag-form'
      type                : 'tags'
      itemDataPath        : 'title'
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : SkillTagAutoCompletedItem
      outputWrapper       : tagWrapper
      selectedItemsLimit  : 10
      form                : this
      dataSource          : ({inputValue}, callback)=>
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        @emit "AutoCompleteNeedsTagData", {inputValue,blacklist,callback}

    @tagController.on 'ItemListChanged', =>
      @loader.show()
      {skillTags} = @getData()
      console.log skillTags
      @memberData.addTags skillTags, (err)=>
        return KD.notify_ "There was an error while adding new skills."  if err
        skillTagsFlat = skillTags.map (tag)-> tag.$suggest ? tag.title
        @doModify {skillTags: skillTagsFlat}, no, @loader.hide.bind @loader

    @addSubView @tagController.getView()
    @tagController.putDefaultValues @memberData.skillTags

  mouseDown:(event)-> no


class SkillTagAutoCompleteController extends KDAutoCompleteController

  constructor:(options = {}, data)->
    options.nothingFoundItemClass or= SuggestNewTagItem
    options.allowNewSuggestions    ?= yes
    super options, data

  putDefaultValues:(stringTags)->
    KD.remote.api.JTag.fetchSkillTags
      title     :
        $in     : stringTags
    ,
      sort      :
        title   : 1
    , (err,tags)=>
        unless err and not tags
          @setDefaultValue tags
        else
          warn "There was a problem fetching default tags!", err, tags

  getCollectionPath:-> 'skillTags'


class SkillTagAutoCompletedItem extends KDAutoCompletedItem

  constructor:(options = {}, data)->
    options.cssClass = "clearfix"
    super options, data

    @tag = new TagLinkView {}, @getData()

  viewAppended: JView::viewAppended
  pistachio:-> "{{> @tag}}"

  click:(event)->
    @getDelegate().removeFromSubmitQueue @ if $(event.target).is('span.close-icon')
    @getDelegate().getView().$input().trigger
