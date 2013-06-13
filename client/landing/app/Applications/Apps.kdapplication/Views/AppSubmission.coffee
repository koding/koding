class AppSubmissionModal extends KDModalViewWithForms
  constructor:->
    options =
      title                     : "Submit an Application"
      width                     : 800
      height                    : "auto"
      cssClass                  : "app-submission"
      overlay                   : yes
      overlayClick              : no
      tabs                      :
        navigable               : no
        callback                : (formOutput)=>
          @emit "AppSubmissionFormSubmitted", formOutput
        forms                   :
          "App Essentials"      :
            buttons             :
              Next              :
                title           : "Next"
                style           : "modal-clean-gray"
                type            : "submit"
            fields              :
              Title             :
                label           : "Title:"
                type            : "text"
                name            : "title"
                placeholder     : "Application title..."
                validate        :
                  rules         :
                    required    : yes
                  messages      :
                    required    : "Title is required!"
              Description       :
                label           : "Description:"
                type            : "textarea"
                name            : "body"
                placeholder     : "short description of the application..."
          "Technical Stuff"     :
            buttons             :
              Next              :
                title           : "Next"
                style           : "modal-clean-gray"
                type            : "submit"
              back1             :
                title           : "← back"
                style           : "modal-cancel"
                callback        : =>
                  @modalTabs.showPreviousPane()
            fields              :
              ScriptInfo        :
                label           : "Description:"
                type            : "textarea"
                name            : "scriptDescription"
                placeholder     : "Install script description..."
              Reqs              :
                label           : "Configuration<br/>builder:"
                cssClass        : "code"
                type            : "textarea"
                # enableTabKey    : yes # needs some work
                name            : "requirementsCode"
                placeholder     : "//write a JSON object"
                validate        :
                  rules         :
                    JSON        : yes
                  messages      :
                    JSON        : "you've entered invalid JSON"
                nextElement     :
                  reqsSyntax    :
                    type          : "hidden"
                    name          : "requirementsSyntax"
                    defaultValue  : "JSON"
              Script            :
                cssClass        : "code"
                label           : "Install script:"
                type            : "textarea"
                # enableTabKey    : yes
                name            : "scriptCode"
                placeholder     : "//write a bash install script"
                nextElement     :
                  scriptSyntax  :
                    type          : "hidden"
                    name          : "scriptSyntax"
                    defaultValue  : "bash"
              Tags              :
                label           : "Tags:"
                type            : "hidden"
                name            : "dummy"
          Visuals               :
            buttons             :
              Next              :
                title           : "Next"
                style           : "modal-clean-gray"
                type            : "submit"
              back              :
                title           : "← back"
                style           : "modal-cancel"
                callback        : =>
                  @modalTabs.showPreviousPane()
            fields              :
              thumbnail         :
                label           : "App Thumbnail"
                type            : "hidden"
                name            : "dummy"
              screenshots       :
                label           : "Screenshots:"
                type            : "hidden"
                name            : "dummy"
          "Review & Submission" :
            buttons             :
              Submit            :
                title           : "Submit"
                style           : "modal-clean-gray"
                type            : "submit"
              back              :
                title           : "← back"
                style           : "modal-cancel"
                callback        : =>
                  @modalTabs.showPreviousPane()

    super options


class AppPreSubmitPreview extends KDScrollView
  constructor:->
    super
    data = @getData()
    @setClass "app-preview"

    scriptData = {syntax : data.scriptSyntax, content : Encoder.htmlEncode(data.scriptCode), title : ""}
    @scriptView = new AppCodeSnippetView {}, scriptData

    requirementsData = {syntax : data.requirementsSyntax, content : Encoder.htmlEncode(data.requirementsCode), title : ""}
    @requirementsView = new AppCodeSnippetView {}, requirementsData

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class='formline title'>
      <label>Title:</label>
      <p>{{ @putThumb #(thumbnails)}}{{#(title)}}</p>
    </div>
    <div class='formline'>
      <label>Description:</label>
      <p>{{#(body)}}</p>
    </div>
    <div class='formline'>
      <label>Install script description:</label>
      <p>{{#(scriptDescription)}}</p>
    </div>
    <div class='formline'>
      <label>Install script:</label>
      {{> @scriptView}}
    </div>
    <div class='formline'>
      <label>Install requirements:</label>
      {{> @requirementsView}}
    </div>
    <div class='formline'>
      <label>Tags:</label>
      <p>{{ @displayTags #(meta.tags)}}</p>
    </div>
    <div class='formline screenshots'>
      <label>Screenshots:</label>
      <p>{{ @putScreenshots #(screenshots)}}</p>
    </div>
    """

  displayTags:(tags = [])->
    spans = tags.map (tag)->
      "<span class='ttag'>#{tag}</span>"
    spans.join('')

  putThumb:(thumbnails = [])->
    if thumbnails.length > 0
      thumb = "<img src='#{thumbnails[0].appThumb}'/>"
    else
      ""

  putScreenshots:(screenshots = [])->
    screenshots = screenshots.map (screenshot)->
      "<img src='#{URL.createObjectURL KDImage.dataURItoBlob screenshot.thumb}'/>"
    screenshots.join ""


class AppCodeSnippetView extends CodeSnippetView

  pistachio:->
    """
    <figure class='code-container'>
      {pre{> @codeView}}
      {{> @syntaxMode}}
    </figure>
    """



# # INSTALL SCRIPT
# formOutput # comes from user prompt
# path = formOutput.path
# db   =
#   host : formOutput.host
#   name : formOutput.name
#   pass : formOutput.pass
#
# script = """
#   #!/bin/bash
#   $path = #{path}
#   $host = #{db.host}
#
#   function wordpressInstall {
#     echo $path
#     echo $host
#   }
#
#   wordpressInstall
#
# """
#
# """
#   #!/bin/bash
#   $path = "/asdas/asdasd"
#   $host = "localhost"
#
#
#   curl $url >$path
#
# """
#
#
#
# #
# # installScript = requirements+"\n"+script
#
#
# # REQUIREMENT SCRIPT
# "Application Path"    :
#   fields              :
#     Path              :
#       label           : "Application path:"
#       type            : "text"
#       name            : "path"
#       placeholder     : "Application path..."
#       validate        :
#         rules         :
#           required    : yes
#         messages      :
#           required    : "Application path is required!"
# "Database details"    :
#   fields              :
#     Host              :
#       label           : "Host:"
#       type            : "text"
#       name            : "host"
#       placeholder     : "Database host..."
#       validate        :
#         rules         :
#           required    : yes
#         messages      :
#           required    : "Database host is required!"
#     Name              :
#       label           : "Name:"
#       type            : "text"
#       name            : "name"
#       placeholder     : "Database name..."
#       validate        :
#         rules         :
#           required    : yes
#         messages      :
#           required    : "Database name is required!"
#     Pass              :
#       label           : "Password:"
#       type            : "password"
#       name            : "pass"
#       placeholder     : "Database password..."
#
