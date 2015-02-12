class SkillTagFormView extends KDFormView
  constructor: (options = {}, data) ->
    options.cssClass = "kdautocomplete-form"
    super options, null

    @memberData = data
    @memberData.skillTags or= []

  showForm: ->
    return if @hasClass 'active'
    @setClass 'active'
    @focusFirstElement()


  viewAppended: ->

    super

    @parent.on "EditingModeToggled", (state)=>
      if state then @showForm() else @unsetClass 'active'

    @addSubView tagWrapper = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "form-actions-holder clearfix"

    tagWrapper.addSubView @label = new KDLabelView
      cssClass    : "skilltagslabel"
      title       : "SKILLS"
      for         : "skillTagsInput"
      click       : =>
        @parent.setEditingMode on

    tagWrapper.addSubView @tip = new KDCustomHTMLView
      tagName     : "span"
      cssClass    : "tip hidden"
      pistachio   : "Adding skills help others to find you more easily."

    @tip.show() if @memberData.skillTags.length is 0

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
      view                : new KDAutoComplete
        placeholder       : 'Add a skill...'
        name              : 'skillTagsInput'
      dataSource          : ({inputValue}, callback) =>
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        @emit "AutoCompleteNeedsTagData", {inputValue,blacklist,callback}

    @tagController.on 'ItemListChanged', =>
      @loader.show()
      {skillTags} = @getData()
      @memberData.addTags skillTags, (err)=>
        return KD.notify_ "There was an error while adding new skills."  if err
        skillTagsFlat = skillTags.map (tag)-> tag.$suggest ? tag.title

        if skillTagsFlat.length then @tip.hide() else @tip.show()

        @memberData.modify
          skillTags: skillTagsFlat,
          (err) =>
            if err
              KD.notify_ 'There was an error updating your skills.'
            @memberData.emit 'update'
            @loader.hide()

    @addSubView @tagController.getView()
    @tagController.putDefaultValues @memberData.skillTags

  mouseDown: (event) -> no
