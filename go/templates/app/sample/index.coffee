
class SampleApp extends KDView

  viewAppended:->

    super

    # Add Documentation Toggle Button
    docToggleButton = new KDOnOffSwitch
      defaultValue  : on
      title         : "Show Documentation: "
      size          : "tiny"
      cssClass      : "test-switch"
      callback      : (state) ->
        if state then bottomSplitView.show() else bottomSplitView.hide()

    @addSubView docToggleButton

    # Get User Information
    {nickname} = KD.whoami().profile

    # Add the Header
    @addSubView @header = new KDHeaderView
      type     : "big"
      title    : "Welcome to your sample application <strong>#{nickname}</strong> made with KDFramework !"

    informationView = new KDView
      cssClass   : "information-box"
      partial    : """
          <p>This is a sample application that you can read the code and get started with. To see usage, go to <code>index.coffee</code>
          just glance at it, you will know how this page is constructed, and you will be able to make cool stuff.</p><br/>

          <p>We want to provide much better documentation about the capabilities of KDFramework very soon, it is what we made <strong>Koding</strong> with.
          Basically every single frontend functionality you see on Koding, will be made available to you piece by piece.</p><br/>
          <p>We will open source KDFramework and publish it to Github so that you can contribute to it, but at this stage
          it's api is not to be relied upon, and everything can change.</p><br/>

          <p>Please bear with us, and use its basic functionalities, soon enough you will be able to make amazing realtime applications with it. Enjoy! :)</p>
      """

    # Create Input Test
    inputView = new KDInputView
      cssClass      : "test-input"
      placeholder   : "Write something to create a notification..."
      validate      :
        event       : "keyup"
        rules       :
          required  : yes
        messages    :
          required  : "That's a very required field..."

    # Update button state based on Input validation
    inputView.on "ValidationError",  -> testButton.disable()
    inputView.on "ValidationPassed", -> testButton.enable()

    # Create Test Button
    testButton = new KDButtonView
      cssClass   : "clean-gray test-input"
      title      : "Create a Notification"
      callback   : ->
        new KDNotificationView
          title : inputView.getValue()

    # Disable the Button, we will enable it if validation passes on input
    testButton.disable()

    # Create a Split View for input and the button
    inputExampleView  = new KDSplitView
      type      : "vertical"
      resizable : no
      sizes     : ["70%", "30%"]
      views     : [inputView, testButton]

    buttonExampleView  = new KDView
      cssClass   : "button-area"

    # Create a Modal Test Button
    modalButton = new KDButtonView
      cssClass : "clean-gray test-input"
      title    : "Create a Modal"
      callback   : ->
        modal = new KDModalView
          title        : "A Modal with a Title"
          content      : "<div class='modalformline'>Do you want to continue?</div>"
          height       : "auto"
          overlay      : yes
          buttons      :
            Continue   :
              loader   :
                color  : "#ffffff"
                diameter : 16
              style    : "modal-clean-gray"
              callback : ->
                new KDNotificationView
                  title: "Lets Continue..."
                modal.destroy()

    buttonExampleView.addSubView modalButton

    showError = ->
      new KDNotificationView
        title    : "An error occured while running the command"
        type     : "mini"
        cssClass : "error"
        duration : 3000

    kiteController = KD.getSingleton "kiteController"

    kiteButton = new KDButtonView
      cssClass   : "clean-gray test-input"
      title      : "Run a command on Server"
      callback   : ->
        modal = new KDModalViewWithForms
          title                   : "Run a command on server-side"
          content                 : "<div class='modalformline'>You can run any bash commands that you run from Terminal</div>"
          overlay                 : yes
          width                   : 600
          height                  : "auto"
          tabs                    :
            navigable             : yes
            forms                 :
              form                :
                buttons           :
                  Run             :
                    cssClass      : "modal-clean-gray"
                    loader        :
                      color       : "#444444"
                      diameter    : 12
                    callback      : ->
                      command = modal.modalTabs.forms.form.inputs.Command.getValue()

                      setTimeout ->
                        if modal.modalTabs.forms.form.buttons.Run.loader.active
                          showError()
                          modal.modalTabs.forms.form.buttons.Clear.getCallback()()
                      , 8000

                      kiteController.run command, (err, res)->
                        showError() if err
                        modal.modalTabs.forms.form.inputs.Output.setValue err or res
                        modal.modalTabs.forms.form.buttons.Run.hideLoader()
                  Clear           :
                    cssClass      : "modal-clean-gray"
                    callback      : ->
                      modal.modalTabs.forms.form.inputs.Output.setValue ''
                      modal.modalTabs.forms.form.buttons.Run.hideLoader()

                fields            :
                  Command         :
                    label         : "Command:"
                    name          : "command"
                    defaultValue  : "ls -la"
                    placeholder   : "Command to run on Server-Side"
                    cssClass      : "command-input"
                  Output          :
                    label         : "Output:"
                    type          : "textarea"
                    name          : "output"
                    placeholder   : "The output of command will be here..."
                    cssClass      : "output-screen"

    buttonExampleView.addSubView kiteButton

    # Open A Koding App
    openActivityButton = new KDButtonView
      cssClass   : "clean-gray test-input"
      title      : "Open Activity Feed"
      callback   : ->
        appManager.openApplication "Activity"

    buttonExampleView.addSubView openActivityButton

    # Create a Description View for Property List
    descriptionView = new KDView
      cssClass : "description-view"

    # Add a Header for Property List
    descriptionView.addSubView subHeader = new KDHeaderView
      type     : "medium"
      title    : "Select a Class from left to see its properties here"

    # Create Class List Controller to control class data
    classListController = new KDListViewController
      viewOptions :
        itemClass : ClassItemView
    ,
      items : ({name: item} for item of KD.classes)

    # Create Class List Controller to control property data
    propertyListController = new KDListViewController
      viewOptions :
        itemClass : PropertyItemView

    # Get their views
    classList = classListController.getView()
    descriptionView.addSubView propertyListController.getView()

    # Create a custom KDView and add header and the list on it
    classView = new KDView
    classView.addSubView new KDHeaderView
      type     : "medium"
      title    : "List of Classes on KD Framework"

    # Follow showClassDetails event from classList
    classListView = classListController.getListView()
    classListView.on "showClassDetails", (className)->
      subHeader.updateTitle className
      obj = KD.classes[className].prototype

      propertyListController.replaceAllItems (item for item of obj)

    classView.addSubView classList

    # Add the Header
    examplesHeader = new KDHeaderView
      type     : "medium"
      title    : "Examples"

    # Add documentation view to bottomSplitView
    bottomSplitView = new KDSplitView
      type      : "vertical"
      cssClass  : "class-model-panel"
      resizable : yes
      sizes     : ["50%",null]
      views     : [ classView, descriptionView ]

    topRightSplitView = new KDSplitView
      type      : "horizontal"
      resizable : no
      sizes     : ["20%", null ,null]
      views     : [ examplesHeader, inputExampleView, buttonExampleView ]

    topSplitView = new KDSplitView
      type      : "vertical"
      resizable : no
      sizes     : ["50%",null]
      views     : [ informationView, topRightSplitView ]

    # Add all of the views to a split
    mainSplitView = new KDSplitView
      type      : "horizontal"
      resizable : no
      sizes     : ["30%", null]
      views     : [ topSplitView, bottomSplitView ]

    # And add that split to the mainView
    @addSubView mainSplitView

class ClassItemView extends KDListItemView

  constructor:(options, data)->
    options.cssClass = "class-item"
    super

  partial:(data)-> "<a href=#> » #{data.name}</a>"

  click:->
    listView = @getDelegate()
    listView.emit "showClassDetails", @getData().name

class PropertyItemView extends ClassItemView

  partial:(data)-> "<a href=#> ► #{data}</a>"

  click:->
    new KDNotificationView
      title: "Documentation will be available soon"

# And let create our App
do ->
  appInstance = new SampleApp

  # appView is a constant that you can use as your app container
  appView.addSubView appInstance
