class AccountSshKeyListController extends KDListViewController
  constructor:(options,data)->
    data = $.extend
      items : [
        { title : "SSH keys are coming soon" }
        # { title : "My Macbook Air",     key:"ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA/qhV71y0s1XkA35CK+KSwKuHPihZI9dxAkGtm/j+c2LwlA6hjJco17mhw2SUWJCFX66zMo2HbAYW2cXfuzAVNg/2RJjzC0s05MPAUiwO0vTg9G08wU4F41yfqKX7ggPZJVq1o6szNkL1u4jhksU05P2OOuSYh9aeuU8tooqQ6I46jzdrdSNyt6FAfd6F+YHvd7ZJIQoQ6aUUF8K1PwTHVbscuu8QRAkjszgZjLf/kcFYc76lD4BQ0d/NNtQzDTTxh1vTgVxWH0Grg5JzUN7Op17ESN800yJc0d9opATu9/nqGwv2vGJDH4q50MySJahlTD51UH7UlmoGz/KctKquDw=="}
        # { title : "Office desktop",     key:"ssh-rsa j+c2LwlA6hjJco17mhw2SUWJCFX66zMo2HbAYW2cXfuzAVNg/2RJjzC0s05MPAUiwO0vTg9G08wU4F41yfqKX7ggPZJVq1o6szNkL1u4jhksU05P2OOuSYh9aeuU8tooqQ6I46jzdrdSNyt6FAfd6FAAAAB3NzaC1yc2EAAAABIwAAAQEA/qhV71y0s1XkA35CK+KSwKuHPihZI9dxAkGtm/+YHvd7ZJIQoQ6aUUF8K1PwTHVbscuu8QRAkjszgZjLf/kcFYc76lD4BQ0d/NNtQzDTTxh1vTgVxWH0Grg5JzUN7Op17ESN800yJc0d9opATu9/nqGwv2vGJDH4q50MySJahlTD51UH7UlmoGz/KctKquDw=="}
        # { title : "Production Server",  key:"ssh-rsa kcFYc76lD4BQ0d/NNtQzDTTxh1vTgVxWH0Grg5JzUN7Op17ESN800yJc0d9opATu9/nqGwv2vGJDH4q50MySJahlTD51UH7UlmoGz/KctKquDwAAAAB3NzaC1yc2EAAAABIwAAAQEA/qhV71y0s1XkA35CK+KSwKuHPihZI9dxAkGtm/j+c2LwlA6hjJco17mhw2SUWJCFX66zMo2HbAYW2cXfuzAVNg/2RJjzC0s05MPAUiwO0vTg9G08wU4F41yfqKX7ggPZJVq1o6szNkL1u4jhksU05P2OOuSYh9aeuU8tooqQ6I46jzdrdSNyt6FAfd6F+YHvd7ZJIQoQ6aUUF8K1PwTHVbscuu8QRAkjszgZjLf/=="}
      ]
    ,data
    super options,data

class AccountSshKeyList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName       : "ul"
      itemClass  : AccountSshKeyListItem
    ,options
    super options,data

class AccountSshKeyForm extends KDFormView
  viewAppended:->

    @addSubView formline1 = new KDCustomHTMLView
      tagName : "div"
      cssClass : "formline"

    formline1.addSubView keyTextarea = new KDInputView
      placeholder  : "paste your sshkey (or type if you can)..."
      type         : "textarea"
      name         : "sshkey"

    keyTextarea.setValue @data.key if @data

    @addSubView formline2 = new KDCustomHTMLView
      cssClass : "button-holder"

    formline2.addSubView save = new KDButtonView
      style        : "clean-gray savebtn"
      title        : "Save"

    formline2.addSubView deletebtn = new KDButtonView
      style        : "clean-red deletebtn"
      title        : "Delete"

    formline2.addSubView whatIsThis = new KDCustomHTMLView
      tagName      : "a"
      partial      : "What is This?"
      cssClass     : "what-link"

    @addSubView actionsWrapper = new KDCustomHTMLView
      tagName : "div"
      cssClass : "actions-wrapper"

    actionsWrapper.addSubView cancel = new KDCustomHTMLView
      tagName      : "a"
      partial      : "cancel"
      cssClass     : "cancel-link"

    # @addSubView deleteLink   = new KDCustomHTMLView
    #   tagName      : "a"
    #   cssClass     : "delete-icon"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : cancel
      callback:() =>
        @handleEvent type : "FormCancelled"



class AccountSshKeyListItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview clearfix #{cssClass}'></li>"

  # viewAppended:()->
  #   super
  #   @form = form = new AccountSshKeyForm
  #     delegate : @
  #     cssClass : "posrelative"
  #   ,@data
  #
  #   @info = info = new KDCustomHTMLView
  #     tagName  : "span"
  #     partial  : "<div class='darkText'>Click edit to get your key...</div>"
  #     cssClass : "posstatic"
  #
  #   info.addSubView editLink = new KDCustomHTMLView
  #     tagName      : "a"
  #     partial      : "Edit"
  #     cssClass     : "action-link"
  #
  #   @swappable = swappable = new AccountsSwappable
  #     views : [form,info]
  #     cssClass : "posstatic"
  #
  #   @addSubView swappable,".swappable-wrapper"
  #
  #   @listenTo KDEventTypes : "click",         listenedToInstance : editLink,   callback : @swapSwappable
  #   @listenTo KDEventTypes : "FormCancelled", listenedToInstance : form,       callback : @swapSwappable

  swapSwappable:()=>
    @swappable.swapViews()

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
    # """
    #   <div class='labelish'>
    #     <span class="icon #{data.type}"></span>
    #     <span class='editor-method-title'>#{data.title}</span>
    #   </div>
    #   <div class='swappableish swappable-wrapper posstatic'></div>
    # """







