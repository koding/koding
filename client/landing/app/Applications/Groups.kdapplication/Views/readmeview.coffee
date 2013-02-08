class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @loader = new KDLoaderView

    @readmeView = new KDView
      cssClass : 'data'
      partial : '<p>Loading Readme</p>'
    
    @readmeInput = new KDInputViewWithPreview
      name        : "body"
      cssClass    : "edit warn-on-unsaved-data"
      type        : "textarea"
      autogrow    : yes
      placeholder : "This is your readme file."
      showHelperModal : no


    @readmeEditButton = new KDButtonView
      title : 'Edit'
      cssClass : 'clean-gray'
      callback :=>
        log @readmeEditButton.getTitle()
        @readmeInput.setValue Encoder.htmlDecode @readme
        @readmeInput.show()
        @readmeView.hide()
        @readmeSaveButton.show()

    @readmeSaveButton = new KDButtonView
      title : "Save"
      cssClass : 'clean-gray'
      loader      :
        color     : "#444444"
        diameter  : 12
      callback: =>
        @readmeView.updatePartial @utils.applyMarkdown @readmeInput.getValue()
        @highlightCode()
        
        group.setReadme @readmeInput.getValue(), (readme)=>
          @readme = readme?.content or 'There was an error.'
          @readmeSaveButton.hideLoader()
          @readmeInput.hide()
          @readmeView.show()
          @readmeSaveButton.hide()
    
    @readmeSaveButton.hide()
    @readmeEditButton.hide()
    @readmeInput.hide()
    @readmeView.hide()

    group.fetchReadme (err, readme)=>

      unless err
        @readmeEditButton.show()

      partial = \
        if err then err.message or "<p>Access denied!</p>"
        else        readme?.content      or "<p>No wiki found...</p>"
      @readme = readme?.content or partial
      @readmeView.updatePartial @utils.applyMarkdown partial 
      @highlightCode()
      @loader.hide()
      @readmeView.show()

  viewAppended:->
    super
    @loader.show()


  highlightCode:=>
    @$(".has-markdown pre").each (i,element)=>
      hljs.highlightBlock element


  pistachio:->
    """
    {{> @loader}}
    <div class="button-bar">
      {{> @readmeEditButton}}
      {{> @readmeSaveButton}}
    </div>
    {{> @readmeInput}}
    <p class="body no-scroll has-markdown">
      {{> @readmeView}}
    </p>
    """
