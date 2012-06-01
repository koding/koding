class SaveDialogController extends KDViewController

  constructor:(options)->
    {callback, @file} = options
    self = @
    options.view = mainView = new KDDialogView
      duration      : 200
      topOffset     : 0
      overlay       : yes
      height        : "auto"
      buttons       :
        Save :
          style     : "modal-clean-gray"
          callback  : ()=>
            items = @finderController.selectedItems
            name  = @inputFileName.inputGetValue()
            
            if name is '' or /^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test(name) is false
              @_message 'Wrong file name', "Please type valid file name"
              return
            
            if items.length is 1 and (items[0].getData().type is 'folder' or items[0].getData().type is 'mount')
              mainView.hide()
              callback?(name, @finderController.pathForItem items[0])
            else
              @_message "Wrong selection", "<div class='modalformline'>In order to save file please select one single folder</div>"
        Cancel :
          style     : "modal-cancel"
          callback  : ()->
            mainView.hide()

    super options

  loadView:(mainView)->
    mainView.addSubView wrapper = new KDView cssClass : "kddialog-wrapper"

    wrapper.addSubView header     = new KDHeaderView type : "medium", title : "Save file as:"
    wrapper.addSubView form       = new KDFormView()

    form.addSubView labelFileName = new KDLabelView title : "Filename:"
    form.addSubView @inputFileName = inputFileName = new KDInputView label : labelFileName, defaultValue : @file.path.split('/').pop()
    form.addSubView labelFinder   = new KDLabelView title : "Select a folder:"

    # mainView.createButton "Save", style : "cupid-green", callback : form.handleEvent({type : "submit"})
    mainView.show()
    inputFileName.inputSetFocus()

    @finderController = new FinderController {}, {items : []}

    form.addSubView finderWrapper = new KDScrollView cssClass : "finder-wrapper save-as-dialog file-container",null
    finderWrapper.addSubView @finderController.getView()
    finderWrapper.$().css "max-height" : "200px"
    @finderController.setEnvironment environment
    
    @listenTo 
      KDEventTypes       : "ItemSelectedEvent"
      listenedToInstance : @finderController
      callback           : (pubInst, view)-> 
        log view.data.name
    
  
  _message: (title, content) ->
    modal = new KDModalView
      title   : title
      content : content
      overlay : no
      cssClass : "new-kdmodal"
      fx : yes
      width : 500
      height : "auto"
      buttons :
        Okay     :
          style     : "modal-clean-gray"
          callback  : ()->
            modal.destroy()