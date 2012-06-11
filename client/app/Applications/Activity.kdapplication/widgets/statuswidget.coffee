class ActivityStatusUpdateWidget extends KDFormView

  constructor:(options,data)->

    super

    {profile} = KD.whoami()

    @smallInput = new KDInputView 
      cssClass      : "status-update-input"
      placeholder   : "What's new #{Encoder.htmlDecode profile.firstName}?"
      name          : 'body'
      style         : 'input-with-extras'
      focus         : => @switchToLargeView()

    @largeInput = new KDInputView
      cssClass      : "status-update-input"
      type          : "textarea"
      placeholder   : "What's new #{Encoder.htmlDecode profile.firstName}?"
      name          : 'body'
      style         : 'input-with-extras'
      validate      :
        rules       : 
          required  : yes
        messages    :
          required  : "Please type a message..."
      keydown       : (input, event)=>
        # this is bad find a way to semantically would fix this - Sinan
        if event.which is 9
          event.stopPropagation()
          event.preventDefault()
          @submitBtn.$().trigger "focus"
    
    @cancelBtn = new KDButtonView
      title       : "Cancel"
      style       : "modal-cancel"
      callback    : =>
        @reset()
        @switchToSmallView()
  
    @submitBtn = new KDButtonView
      style       : "clean-gray"
      title       : "Submit"
      type        : "submit"

    @heartBox = new HelpBox
      subtitle : "About Status Updates"
      tooltip  :
        title  : "This a public wall, here you can share anything with the Koding community."

    # @labelAddTags = new KDLabelView
    #   title : "Add Tags:"
    # 
    # @selectedItemWrapper = new KDCustomHTMLView
    #   tagName  : "div"
    #   cssClass : "tags-selected-item-wrapper clearfix"

    # @tagController = new TagAutoCompleteController
    #   name                : "meta.tags"
    #   type                : "tags"
    #   itemClass           : TagAutoCompleteItemView
    #   selectedItemClass   : TagAutoCompletedItemView
    #   outputWrapper       : @selectedItemWrapper
    #   selectedItemsLimit  : 5
    #   listWrapperCssClass : "tags"
    #   form                : @
    #   itemDataPath        : "title"
    #   dataSource          : (args, callback)=>
    #     {inputValue} = args
    #     updateWidget = @getDelegate()
    #     blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
    #     appManager.tell "Topics", "fetchTopics", {inputValue, blacklist}, callback
    # 
    # @tagAutoComplete = @tagController.getView()
    
  switchToSmallView:->
    
    @parent.setClass "no-shadow"
    @largeInput.setHeight 33
    @$('>div').hide()
    @smallInput.show()
    
  switchToLargeView:->

    @parent.unsetClass "no-shadow"
    @smallInput.hide()
    @$('>div').show()

    @utils.nextTick => 
      @largeInput.$().trigger "focus"
      @largeInput.setHeight 72

    tabView = @parent.getDelegate()
    @getSingleton("windowController").addLayer tabView
    
  # inputKeyDown:(event)->
  #   if event.which is 13 and (event.altKey or event.shiftKey) isnt true
  #     @submitStatusUpdate()
  #     event.preventDefault()
  #     event.stopPropagation()
  #     return no

  viewAppended:->
    
    @setTemplate @pistachio()
    @template.update()
    @switchToSmallView()
    tabView = @parent.getDelegate()
    tabView.on "MainInputTabsReset", => @switchToSmallView()

  pistachio:->

    """
    {{> @smallInput}}
    <div>{{> @largeInput}}</div>
    <div class="formline submit">
      {{> @heartBox}}
      <div class="submit-box">
        {{> @cancelBtn}}{{> @submitBtn}}
      </div>
    </div>
    """
    
    # """
    # {{> @smallInput}}
    # <div>{{> @largeInput}}{{> @tagAutoComplete}}</div>
    # {{> @selectedItemWrapper}}
    # <div class="formline submit">
    #   {{> @heartBox}}
    #   <div class="submit-box">
    #     {{> @cancelBtn}}{{> @submitBtn}}
    #   </div>
    # </div>
    # """
    
  