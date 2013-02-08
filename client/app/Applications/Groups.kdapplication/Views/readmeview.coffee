class GroupReadmeView extends JView

  constructor:->

    super

    @setClass "readme"

    group = @getData()

    @loader = new KDLoaderView

    @readmeView = new KDView
    
    @readmeButton = new KDButtonView
      title : 'Edit'
      cssClass : 'clean-gray'
      callback :=>
        modal = new KDModalView
          title : 'Edit the Readme'
          buttons : 
            "Save" : 
              title : 'Save'
              style : 'modal-clean-gray'
              callback :=>
                @readmeView.updatePartial @utils.applyMarkdown @readmeInput.getValue()
                @highlightCode()
                modal.destroy()
                
                group.setReadme @readmeInput.getValue(), (readme)=>
                  @readme = readme?.content or 'There was an error.'

            "Cancel" :
              title : 'Cancel'
              style : 'modal-clean-gray'
              callback :=>
                modal.destroy()    
        
        modal.addSubView @readmeInput = new KDInputViewWithPreview
          preview     : {}
          name        : "body"
          cssClass    : "readme-text warn-on-unsaved-data"
          type        : "textarea"
          autogrow    : yes
          placeholder : "This is your readme file."
          showHelperModal : no

        @readmeInput.setValue Encoder.htmlDecode @readme

    group.fetchReadme (err, readme)=>
      partial = \
        if err then err.message or "Access denied!"
        else        readme?.content      or "No wiki found..."

      @readme = readme?.content or partial
      @readmeView.updatePartial @utils.applyMarkdown partial 
      @highlightCode()
      @loader.hide()

  viewAppended:->

    super

    @loader.show()


  highlightCode:=>
    @$(".has-markdown pre").each (i,element)=>
      hljs.highlightBlock element


  pistachio:->
    """
    {{> @loader}}
    {{> @readmeButton}}
    <p class="body no-scroll has-markdown">
      {{> @readmeView}}
    </p>
    """
