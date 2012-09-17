class ActivityCodeShareWidget extends KDFormView

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

    @codeShareResultView = new CodeShareResultView {}, {}
    @codeShareResultView.hide()
    @codeShareResultButton = new KDButtonView
      title: "Run this Code Share"
      cssClass:"clean-gray result-button"
      click:=>
        @codeShareResultButton.setTitle "Refresh Code Share"
        @codeShareResultView.show()
        @codeShareCloseButton.show()
        @codeShareResultView.emit "CodeShareSourceHasChanges", {
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

    @codeShareCloseButton = new KDButtonView
      title: "Stop and Close this Code Share"
      cssClass:"clean-gray hidden"
      click:=>
        @codeShareResultView.hide()
        @codeShareResultView.resetResultFrame()
        @codeShareResultButton.setTitle "Run this Code Share"
        @codeShareCloseButton.hide()

## LIBRARY OVERLAYS

    @librariesHTMLContent = new KDView
      cssClass : "libs-container libs-html"

    @librariesCSSContent = new KDView
      cssClass : "libs-container libs-css"

    @librariesJSContent = new KDView
      cssClass : "libs-container libs-js"

    @libHTMLSelect = new KDSelectBox
      title : "HTML Modes"
      name  : "modeHTML"
      selectOptions:
        [
          {
            title:"HTML"
            value:"html"
          }
          {
            title:"Markdown"
            value:"markdown"
          }
        ]

    @libCSSSelect = new KDSelectBox
      title : "CSS Modes"
      name  : "modeCSS"
      selectOptions:
        [
          {
            title:"CSS"
            value:"css"
          }
        ]

    @libJSSelect = new KDSelectBox
      title : "JS Modes"
      name  : "modeJS"
      selectOptions:
        [
          {
            title:"JavaScript"
            value:"javascript"
          }
          {
            title:"CoffeeScript"
            value:"coffee-script"
          }
        ]

    @libHTMLClasses = new KDInputView
      name : "classesHTML"
      cssClass : "libs-html-input"
      placeholder : "extra html classes"

    @libHTMLHeadExtras = new KDInputView
      name : "extrasHTML"
      cssClass : "libs-html-input"
      placeholder : "extra head tags"

    @libCSSExternal = new KDInputView
      name : "externalCSS"
      cssClass : "libs-html-input"
      placeholder : "external css files"

    @libJSExternal = new KDInputView
      name : "externalJS"
      cssClass : "libs-html-input"
      placeholder : "external JS files"

    @libCSSPrefix = new KDInputView
      type : "checkbox"
      name : "prefixCSSCheck"
      cssClass : "libs-css-checkbox"
      title : "PrefixFree"
      partial : "PrefixFree"

    @libCSSResets = new KDInputRadioGroup
      name : "resetsCSS"
      title: "CSS Resets"
      radios: [
        {
          title:"Reset"
          value:"reset"
        }
        {
          title:"Normalize"
          value:"normalize"
        }
        {
          title:"None"
          value:"none"
        }
      ]

    @libJSSelectLibs = new KDSelectBox
      title : "JS Libraries"
      name  : "libsJS"
      selectOptions:
        [
          {
            title:"none (JQuery-latest is always included)"
            value:"none"
          }
          {
            title:"JQuery latest with JQuery UI"
            value:"jquery-latest-with-ui"
          }
          {
            title:"MooTools latest"
            value:"mootools-latest"
          }
        ]

    @libJSModernizr = new KDInputView
      type : "checkbox"
      name : "modernizeJSCheck"
      cssClass : "libs-js-checkbox"
      title : "Modernizr"
      partial : "Modernizr"

    @librariesHTMLContent.addSubView @libHTMLSelect
    @librariesHTMLContent.addSubView @libHTMLClasses
    @librariesHTMLContent.addSubView @libHTMLHeadExtras

    @librariesCSSContent.addSubView @libCSSSelect
    @librariesCSSContent.addSubView @libCSSPrefix
    @librariesCSSContent.addSubView @libCSSResets
    @librariesCSSContent.addSubView @libCSSExternal

    @librariesJSContent.addSubView @libJSSelect
    @librariesJSContent.addSubView @libJSSelectLibs
    @librariesJSContent.addSubView @libJSModernizr
    @librariesJSContent.addSubView @libJSExternal



    @labelHTMLContent.$().hover =>
      @$("div.libs-html").css "opacity":1
      @$("div.libs-html").css "z-index":100

    , =>
      @$("div.libs-html").hover =>
        noop
      , =>
        @$("div.libs-html").css "opacity":0
        @$("div.libs-html").css "z-index":-1

    @labelCSSContent.$().hover =>
      @$("div.libs-css").css "opacity":1
      @$("div.libs-css").css "z-index":100
    , =>
      @$("div.libs-css").hover =>
        noop
      , =>
        @$("div.libs-css").css "opacity":0
        @$("div.libs-css").css "z-index":-1

    @labelJSContent.$().hover =>
      @$("div.libs-js").css "opacity":1
      @$("div.libs-js").css "z-index":100
    , =>
      @$("div.libs-js").hover =>
        noop
      , =>
        @$("div.libs-js").css "opacity":0
        @$("div.libs-js").css "z-index":-1


  submit:=>

    if not (@getData().prefixCSSCheck?) or (@getData().prefixCSS is "off")
      @addCustomData "prefixCSS", "off"
    else
      @addCustomData "prefixCSS", "on"

    if not (@getData().modernizeJSCheck?) or (@getData().modernizeJS is "off")
      @addCustomData "modernizeJS", "off"
    else
      @addCustomData "modernizeJS", "on"

    @addCustomData "resetsCSS", @getData().resetsCSS

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

    @libHTMLClasses.setValue ''
    @libHTMLHeadExtras.setValue ''
    @libCSSExternal.setValue ''
    @libJSExternal.setValue ''

    @addCustomData "prefixCSS", "off"
    @addCustomData "modernizeJS", "off"

    @$("input[name=prefixCSSCheck]").prop "checked", false
    @$("input[name=modernizeJSCheck]").prop "checked", false

    @$(":radio[value=none]").prop "checked", true

    @$("select[name=modeHTML]").val("html").trigger "change"
    @$("select[name=modeCSS]").val("css").trigger "change"
    @$("select[name=modeJS]").val("javascript").trigger "change"

    @$("select[name=libsJS]").val("none").trigger "change"

    @utils.wait =>
      @HTMLace.setContents "//your HTML goes here..."
      @HTMLace.setSyntax 'html'
      @CSSace.setContents "//your CSS goes here..."
      @CSSace.setSyntax 'css'
      @JSace.setContents "//your JavaScript goes here..."
      @JSace.setSyntax 'javascript'
      @codeShareResultView?.resetResultFrame()
      @codeShareResultView?.hide()
      @codeShareCloseButton?.hide()
      @codeShareResultButton?.setTitle "Run"
    @tagController.reset()

  switchToEditView:(activity)->
    @submitBtn.setTitle "Edit your Code Share"
    @addCustomData "activity", activity
    {title, body, tags, prefixCSS, resetsCSS, classesHTML, extrasHTML, modeHTML, modeCSS, modeJS, libsJS, externalCSS, externalJS, modernizeJS} = activity

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

      if prefixCSS is "on"
        @$("input[name=prefixCSSCheck]").prop "checked", true
      else
        @$("input[name=prefixCSSCheck]").prop "checked", false

      if modernizeJS is "on"
        @$("input[name=modernizeJSCheck]").prop "checked", true
      else
        @$("input[name=modernizeJSCheck]").prop "checked", false

      @$(":radio[value=#{resetsCSS}]").prop "checked", true

      @$("select[name=modeHTML]").val(modeHTML).trigger "change"
      @$("select[name=modeCSS]").val(modeCSS).trigger "change"
      @$("select[name=modeJS]").val(modeJS).trigger "change"

      @$("select[name=libsJS]").val(libsJS).trigger "change"

      @$("input[name=classesHTML]").val(classesHTML)
      @$("input[name=extrasHTML]").val(extrasHTML)
      @$("input[name=externalCSS]").val(externalCSS)
      @$("input[name=externalJS]").val(externalJS)





    if @HTMLace?.editor? and @CSSace?.editor? and @JSace?.editor?
      fillForm()
    else
      @once "codeShare.aceLoaded", => fillForm()

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
      @once "codeShare.aceLoaded", => fillForm()

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

      @emit "codeShare.aceLoaded"

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

    @setClass "update-options codeshare"
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
          {{> @librariesHTMLContent}}
          <div class="code-snip-holder share">
            {{> @HTMLloader}}
            {{> @aceHTMLWrapper}}
          </div>
        </div>
        <div class="code-snip-container">
          {{> @labelCSSContent}}
          {{> @librariesCSSContent}}
          <div class="code-snip-holder share">
            {{> @CSSloader}}
            {{> @aceCSSWrapper}}
          </div>
        </div>
        <div class="code-snip-container">
          {{> @labelJSContent}}
          {{> @librariesJSContent}}
          <div class="code-snip-holder share">
            {{> @JSloader}}
            {{> @aceJSWrapper}}
          </div>
        </div>
        </div>
        <div class="formline">
          {{> @codeShareResultView}}
          {{> @codeShareResultButton}}
          {{> @codeShareCloseButton}}
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
