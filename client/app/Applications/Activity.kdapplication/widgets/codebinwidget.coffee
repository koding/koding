class ActivityCodeBinWidget extends KDFormView

  constructor:->

    super

    @labelTitle = new KDLabelView
      title         : "Title:"
      cssClass      : "first-label"

    @title = new KDInputView
      name          : "title"
      placeholder   : "Give a title to your code ..."
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Code title is required!"

    @labelDescription = new KDLabelView
      title : "Description:"

    @description = new KDInputView
      label       : @labelDescription
      name        : "body"
      placeholder : "What is your code about?"

    @labelAddTags = new KDLabelView
      title : "Add Tags:"

    @cancelBtn = new KDButtonView
      title    : "Cancel"
      style    : "modal-cancel"
      callback : =>
        @reset()
        @parent.getDelegate().emit "ResetWidgets"

    @submitBtn = new KDButtonView
      style : "clean-gray"
      title : "Share your Code Bin"
      type  : 'submit'

    @heartBox = new HelpBox
      subtitle    : "About Code Sharing"
      tooltip     :
        title     : "Easily share your code with other members of the Koding community. Once you share, user can easily open or save your code to their own environment."

    @selectedItemWrapper = new KDCustomHTMLView
      tagName  : "div"
      cssClass : "tags-selected-item-wrapper clearfix"

    @tagController = new TagAutoCompleteController
      name                : "meta.tags"
      type                : "tags"
      itemClass           : TagAutoCompleteItemView
      selectedItemClass   : TagAutoCompletedItemView
      itemDataPath        : 'title'
      outputWrapper       : @selectedItemWrapper
      selectedItemsLimit  : 5
      listWrapperCssClass : "tags"
      form                : @
      dataSource          : (args, callback)=>
        {inputValue} = args
        updateWidget = @getDelegate()
        blacklist = (data.getId() for data in @tagController.getSelectedItemData() when 'function' is typeof data.getId)
        appManager.tell "Topics", "fetchTopics", {inputValue, blacklist}, callback

    @tagAutoComplete = @tagController.getView()

    @labelHTMLContent = new KDLabelView
      title : "HTML:"

    @aceHTMLWrapper = new KDView

    @HTMLloader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#ffffff"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @HTMLfullScreenBtn = new KDButtonView
      style           : "clean-gray"
      cssClass        : "fullscreen-button"
      title           : "Fullscreen HTML Editor"
      callback: =>
        modal = new KDModalView
          title       : "What do you want to discuss?"
          cssClass    : "modal-fullscreen"
          height      : $(window).height()-110
          width       : $(window).width()-110
          position:
            top       : 55
            left      : 55
          overlay     : yes
          content     : "" #"<div class='modal-fullscreen-text'><textarea class='kdinput text' id='fullscreen-data'>"+@HTMLace.getContents()+"</textarea></div>"
          buttons     :
            Cancel    :
              title   : "Discard changes"
              style   : "modal-clean-gray"
              callback:=>
                modal.destroy()
            Apply     :
              title   : "Apply changes"
              style   : "modal-clean-gray"
              callback:=>
                @HTMLace.setContents $("#fullscreen-data").val()
                modal.destroy()

        modal.$(".kdmodal-content").height modal.$(".kdmodal-inner").height()-modal.$(".kdmodal-buttons").height()-modal.$(".kdmodal-title").height()-12 # minus the margin, border pixels too..
        # modal.$("#fullscreen-data").height modal.$(".kdmodal-content").height()-10
        # modal.$("#fullscreen-data").width modal.$(".kdmodal-content").width()-20

    @labelCSSContent = new KDLabelView
      title : "CSS:"

    @aceCSSWrapper = new KDView

    @CSSloader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#ffffff"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @labelJSContent = new KDLabelView
      title : "JavaScript:"

    @aceJSWrapper = new KDView

    @JSloader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : "#ffffff"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @codeBinResultView = new CodeBinResultView {}, {}
    @codeBinResultView.hide()
    @codeBinResultButton = new KDButtonView
      title: "Run this Code Share"
      cssClass:"clean-gray result-button"
      click:=>
        @codeBinResultButton.setTitle "Refresh Code Share"
        @codeBinResultView.show()
        @codeBinCloseButton.show()
        @codeBinResultView.emit "CodeBinSourceHasChanges", {
          attachments:[
            {
              content:@HTMLace.getContents()
              title:"irrelevant"
              syntax:"html"},
            {
              content:@CSSace.getContents()
              title:"irrelevant"
              syntax:"css"
              },
            {
              content:@JSace.getContents()
              title:"irrelevant"
              syntax:"javascript"
            }
            ]
          }

    @codeBinCloseButton = new KDButtonView
      title: "Stop and Close this Code Share"
      cssClass:"clean-gray hidden"
      click:=>
        @codeBinResultView.hide()
        @codeBinResultView.resetResultFrame()
        @codeBinResultButton.setTitle "Run this Code Share"
        @codeBinCloseButton.hide()

    # @syntaxSelect = new KDSelectBox
    #   name          : "syntax"
    #   selectOptions : __aceSettings.getSyntaxOptions()
    #   defaultValue  : "javascript"
    #   callback      : (value) => @emit "codeSnip.changeSyntax", value

    # @on "codeSnip.changeSyntax", (syntax)=>
    #   @updateSyntaxTag syntax
    #   @HTMLace.setSyntax syntax

  # updateSyntaxTag:(syntax)=>
  #   # Remove already appended syntax tag from submit queue if exists
  #   # FIXME It still fails for meta characters like /
  #   # oldSyntax = __aceSettings.syntaxAssociations[@ace.getSyntax()][0].toLowerCase()
  #   oldSyntax = @HTMLace.getSyntax()
  #   subViews = @tagController.itemWrapper.getSubViews().slice()
  #   for item in subViews
  #     if item.getData().title is oldSyntax
  #       @tagController.removeFromSubmitQueue(item)
  #       break

  #   {selectedItemsLimit} = @tagController.getOptions()
  #   # Add new syntax tag to submit queue
  #   if @tagController.selectedItemCounter < selectedItemsLimit
  #     @tagController.addItemToSubmitQueue @tagController.getNoItemFoundView(syntax)

  submit:=>
    @addCustomData "codeHTML", Encoder.htmlEncode @HTMLace.getContents()
    @addCustomData "codeCSS", Encoder.htmlEncode @CSSace.getContents()
    @addCustomData "codeJS", Encoder.htmlEncode @JSace.getContents()
    @once "FormValidationPassed", => @reset()
    super

  reset:=>
    @submitBtn.setTitle "Post your Code Share"
    @removeCustomData "activity"
    @title.setValue ''
    @description.setValue ''
    @utils.wait =>
      @HTMLace.setContents "//your HTML goes here..."
      @HTMLace.setSyntax 'html'
      @CSSace.setContents "//your CSS goes here..."
      @CSSace.setSyntax 'css'
      @JSace.setContents "//your JavaScript goes here..."
      @JSace.setSyntax 'javascript'
      @codeBinResultView?.resetResultFrame()
      @codeBinResultView?.hide()
      @codeBinCloseButton?.hide()
      @codeBinResultButton?.setTitle "Run"
    @tagController.reset()

  switchToEditView:(activity)->
    @submitBtn.setTitle "Edit your Code Share"
    @addCustomData "activity", activity
    {title, body, tags} = activity

    HTMLcontent = activity.attachments[0]?.content
    CSScontent = activity.attachments[1]?.content
    JScontent = activity.attachments[2]?.content

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      @title.setValue Encoder.htmlDecode title
      @description.setValue Encoder.htmlDecode body
      @HTMLace.setContents Encoder.htmlDecode HTMLcontent
      @CSSace.setContents Encoder.htmlDecode CSScontent
      @JSace.setContents Encoder.htmlDecode JScontent

    if @HTMLace?.editor? and @CSSace?.editor? and @JSace?.editor?
      fillForm()
    else
      @once "codeBin.aceLoaded", => fillForm()

  switchToForkView:(activity)->
    @submitBtn.setTitle "Fork this Code Share"
    # @addCustomData "activity", activity
    {title, body, tags} = activity

    HTMLcontent = activity.attachments[0]?.content
    CSScontent = activity.attachments[1]?.content
    JScontent = activity.attachments[2]?.content

    @tagController.reset()
    @tagController.setDefaultValue tags or []

    fillForm = =>
      # @title.setValue Encoder.htmlDecode title
      # @description.setValue Encoder.htmlDecode body
      @HTMLace.setContents Encoder.htmlDecode HTMLcontent
      @CSSace.setContents Encoder.htmlDecode CSScontent
      @JSace.setContents Encoder.htmlDecode JScontent

    if @HTMLace?.editor? and @CSSace?.editor? and @JSace?.editor?
      fillForm()
    else
      @once "codeBin.aceLoaded", => fillForm()

  widgetShown:->

    snippetCount = 0

    unless @HTMLace? and @CSSace? and @JSace?
      @loadAce()
    else
      @refreshEditorView()

  snippetCount = 0

  loadAce:->

    @HTMLloader.show()
    @CSSloader.show()
    @JSloader.show()

    @aceHTMLWrapper.addSubView @HTMLace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"
    @aceCSSWrapper.addSubView @CSSace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"
    @aceJSWrapper.addSubView @JSace = new Ace {}, FSHelper.createFileFromPath "localfile:/codesnippet#{snippetCount++}.txt"

    @HTMLace.on "ace.ready", =>

      @HTMLloader.destroy()
      @HTMLace.setShowGutter no
      @HTMLace.setContents "//your html goes here..."
      @HTMLace.setTheme()
      @HTMLace.setFontSize(12, no)
      @HTMLace.setSyntax "html"
      @HTMLace.editor.getSession().on 'change', => @refreshEditorView()

      @CSSloader.destroy()
      @CSSace.setShowGutter no
      @CSSace.setContents "//your css goes here..."
      @CSSace.setTheme()
      @CSSace.setFontSize(12, no)
      @CSSace.setSyntax "css"
      @CSSace.editor.getSession().on 'change', => @refreshEditorView()

      @JSloader.destroy()
      @JSace.setShowGutter no
      @JSace.setContents "//your javascript goes here..."
      @JSace.setTheme()
      @JSace.setFontSize(12, no)
      @JSace.setSyntax "javascript"
      @JSace.editor.getSession().on 'change', => @refreshEditorView()

      @emit "codeBin.aceLoaded"

  refreshEditorView:->
    # lines = @HTMLace.editor.selection.doc.$lines
    # lineAmount = if lines.length > 10 then 10 else if lines.length < 5 then 5 else lines.length
    # @setAceHeightByLines lineAmount

  setAceHeightByLines: (lineAmount) ->
    lineHeight  = @HTMLace.editor.renderer.lineHeight
    container   = @HTMLace.editor.container
    height      = lineAmount * lineHeight
    @$('.code-snip-holder').height height + 20
    @HTMLace.editor.resize()
    @CSSace.editor.resize()
    @JSace.editor.resize()

  viewAppended:()->

    @setClass "update-options codebin"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="form-actions-mask">
      <div class="form-actions-holder code-share">
        <div class="formline">
          {{> @labelTitle}}
          <div>
            {{> @title}}
          </div>
        </div>
        <div class="formline">
          {{> @labelDescription}}
          <div>
            {{> @description}}
          </div>
        </div>
        <div class="formline-codeshare">
        <div class="code-snip-container">
          {{> @labelHTMLContent}}
          <div class="code-snip-holder share">
            {{> @HTMLloader}}
            {{> @aceHTMLWrapper}}
          </div>
        </div>
        <div class="code-snip-container">
          {{> @labelCSSContent}}
          <div class="code-snip-holder share">
            {{> @CSSloader}}
            {{> @aceCSSWrapper}}
          </div>
        </div>
        <div class="code-snip-container">
          {{> @labelJSContent}}
          <div class="code-snip-holder share">
            {{> @JSloader}}
            {{> @aceJSWrapper}}
          </div>
        </div>
        </div>
        <div class="formline">
          {{> @codeBinResultView}}
          {{> @codeBinResultButton}}
          {{> @codeBinCloseButton}}
        </div>
        <div class="formline">

        </div>
        <div class="formline">
          {{> @labelAddTags}}
          <div>
            {{> @tagAutoComplete}}
            {{> @selectedItemWrapper}}
          </div>
        </div>
        <div class="formline submit">
          <div class='formline-wrapper'>
            <div class="submit-box fr">
              {{> @submitBtn}}
              {{> @cancelBtn}}
            </div>
            {{> @heartBox}}
          </div>
        </div>
      </div>
    </div>
    """
