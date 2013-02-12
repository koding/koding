class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @loader           = new KDLoaderView
      cssClass        : 'loader'
    @loaderText       = new KDView
      partial         : 'Loading Readme…'
      cssClass        : ' loader-text'

    @readmeView       = new KDView
      cssClass        : 'data'
      partial         : '<p>Loading Readme</p>'
    
    @readmeInput      = new KDInputViewWithPreview
      name            : "body"
      cssClass        : "edit warn-on-unsaved-data"
      type            : "textarea"
      autogrow        : yes
      placeholder     : "This is your readme file."
      showHelperModal : no

    @readmeEditButton = new KDButtonView
      title           : 'Edit the Readme'
      cssClass        : 'clean-gray'
      callback        : =>
        @readmeInput.setValue Encoder.htmlDecode @readme
        @readmeView.hide()
        @showReadmeEditButtons()
        @readmeEditButton.hide()

    @readmeSaveButton = new KDButtonView
      title           : "Save Changes"
      cssClass        : 'clean-gray'
      loader          :
        color         : "#444444"
        diameter      : 12
      callback        : =>
        previousValue = @readmeInput.getValue()
        @readmeView.updatePartial @utils.applyMarkdown @readmeInput.getValue()
        @highlightCode()
        
        group.setReadme @readmeInput.getValue(), (err, readme)=>
          @readme = readme?.content or previousValue
          if err
            @readmeView.updatePartial previousValue
          @readmeSaveButton.hideLoader()
          @readmeView.show()
          @hideReadmeEditButtons()
          @readmeEditButton.show() unless err

    @readmeCancelLink = new CustomLinkView
      title           : 'Cancel'
      cssClass        : 'edit-cancel'
      click           : =>
        @readmeView.show()
        @hideReadmeEditButtons()
        @readmeEditButton.show()

    @readmeView.hide()
    @readmeInput.hide()
    @readmeEditButton.hide()
    @hideReadmeEditButtons()

    group.fetchReadme (err, readme)=>
      unless err
        partial = readme?.content or "This group does not have any associated readme data yet."
        group.canEditGroup (err, allowed)=>
          if allowed
            @readmeEditButton.show() 
      else 
        partial = err.message or "Access denied! Please join the group."
      
      @readme = readme?.content or partial
      @readmeView.updatePartial @utils.applyMarkdown partial 
      @readmeView.show()
      @highlightCode()
      @loader.hide()
      @loaderText.hide()

  hideReadmeEditButtons:->
    @readmeInput.hide()
    @readmeSaveButton.hide()
    @readmeCancelLink.hide() 

  showReadmeEditButtons:->
    @readmeInput.show()
    @readmeSaveButton.show()
    @readmeCancelLink.show()

  viewAppended:->
    super
    @loader.show()


  highlightCode:=>
    @$(".has-markdown pre").each (i,element)=>
      hljs.highlightBlock element


  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    <div class="button-bar">
      {{> @readmeEditButton}}
      {{> @readmeCancelLink}}
      {{> @readmeSaveButton}}
    </div>
    {{> @readmeInput}}
    <p class="body no-scroll has-markdown">
      {{> @readmeView}}
    </p>
    """
