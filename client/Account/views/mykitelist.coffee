class AccountMyKiteListController extends KDListViewController

  constructor:(options,data)->
    options.cssClass = "kites"
    super options,data

  loadView:->
    super

    KD.remote.api.JKite.fetchAll {}, (err, kites) =>
      if err then warn err
      else
        @instantiateListItems kites

    list = @getListView()
    @getView().parent.addSubView addButton = new KDButtonView
      style     : "solid green small account-header-button"
      title     : "Add new Kite"
      icon      : yes
      iconOnly  : yes
      iconClass : "plus"
      tooltip     :
        title     : "Add new Kite"
        placement : "left"
      callback  : =>
        list.showModal()

    ##################### Events ############################
    list.on "DeleteKiteSubmitted", @bound "deleteKite"

    list.on "UpdateKiteSubmitted", @bound "updateKite"

    list.on "CreateKiteSubmitted", @bound "createKite"

    @on "KiteDeleted", list.bound "removeItem"

    # @on "KiteUpdated", list.bound ""

    @on "KiteCreated", (itemData)=>
      list.addItem itemData, null, {type : "slideDown", duration : 100}
      new KDModalView
        title   : "New Kite Information"
        width   : 580
        overlay : yes
        content : """
                  <div class='modalformline'>
                    <p><label>Decription:  </label> <i>#{itemData.description}</i></p>
                    <p><label>Kite Name :  </label> <i>#{itemData.kiteName}</i></p>
                    <p><label>Kite Key  :  </label> <b>#{itemData.key}</b></p>
                  </div>
                  """
                  #<p><label>Status    :  </label> <b>#{itemData.status}</b></p>
                  #<p><label>Privacy   :  </label> <b>#{itemData.privacy}</b></p>
                  #<p><label>Type      :  </label> <b>#{itemData.type}</b></p>

  deleteKite: (listItem)->
    data = listItem.getData()
    KD.remote.api.JKite.get
      id: data.id
      (err, kite) =>
        if err
          @notify err.message, "fail"
        else
          if kite?
            kite.delete (err, success)=>
              if err == null
                @notify 'Your kite is deleted', "success"
          else
            @notify 'Kite is not found', "fail"

  updateKite:(listItem, formData)->
    throw new Error 'not implemented yet!'
    @emit "KiteUpdated", kite

  createKite : (form)->
    { description
      kiteName
      purchaseAmount
      callCount
      privacy
      type
    } = form.modal.modalTabs.forms.MyKites.inputs

    data = {
      description  : description.getValue()
      kiteName     : kiteName.getValue()
      privacy      : privacy.getValue()
      type         : type.getValue()
    }

    if type.getValue() == 'paid'
      data.purchaseAmount = purchaseAmount.getValue()
      data.count          = callCount.getValue()

    KD.remote.api.JKite.create data,(err, kite) =>
      if err
        @notify err.message, "fail"
        form.modal.modalTabs.forms.MyKites.buttons.create.hideLoader()
      else
        @notify 'Your kite is created', "success"
        @emit "KiteCreated", kite
        form.modal.destroy()

  notify:(title, type)->
    {modal} = @getListView()
    new KDNotificationView
      type      : "mini"
      cssClass  : "#{type}"
      title     : "<p>#{title}</p>"
      duration  : 3000


class AccountMyKiteList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName   : "ul"
      itemClass : AccountMyKiteListItem
    ,options
    super options,data

  showModal:=>
    modal = @modal = new KDModalViewWithForms
      title                           : "Create a new Kite"
      content                         : ""
      overlay                         : yes
      cssClass                        : "new-kdmodal"
      width                           : 500
      height                          : "auto"
      tabs                            :
        forms                         :
          MyKites                     :
            callback                  : =>
              @modal.modalTabs.forms.MyKites.buttons.create.showLoader()
              @emit "CreateKiteSubmitted", @
            buttons                   :
              create                  :
                title                 : "Create"
                style                 : "modal-clean-gray"
                type                  : "submit"
                loader                :
                  color               : "#444444"
                callback              : -> @hideLoader()
              cancel                  :
                title                 : "Cancel"
                style                 : "modal-cancel"
                callback              : (event)-> modal.destroy()
            fields                    :
              kiteName               :
                label                : "Name"
                itemClass            : KDInputView
                name                 : "name"
                placeholder          : "Name..."
                validate             :
                  rules              :
                    required         : yes
                    rangeLength      : [4,25]
                    regExp           : /^[a-z\d]+([-][a-z\d]+)*$/i
                    kiteNameCheck    : (input, event) => @kiteNameCheck input, event
                    finalCheck       : (input, event) => @kiteNameCheck input, event
                  messages           :
                    required         : "Please enter a kite name"
                    regExp           : "For kite name only lowercase letters and numbers are allowed!"
                    rangeLength      : "kite name should be minimum 4 maximum 25 chars!"
                  events             :
                    required         : "blur"
                    rangeLength      : "keyup"
                    regExp           : "keyup"
                    usernameCheck    : "keyup"
                    finalCheck       : "blur"
                iconOptions          :
                  tooltip            :
                    placement        : "right"
                    offset           : 2
                    title            : """
                                       Only lowercase letters and numbers are allowed,
                                       max 25 characters.
                                       """
              type                    :
                label                 : "Type"
                itemClass             : KDSelectBox
                cssClass              : "kiteType"
                type                  : "select"
                tooltip               :
                  title               : "Paid Kites are coming soon"
                  placement           : "right"
                name                  : "type"
                defaultValue          : "free"
                selectOptions         : [
                  { title : "Free",                   value : "free" }
                  { title : "Paid - Coming Soon!",    value : "paid" }
                ]
                change        : ->
                  if @getValue() is "paid"
                    @setValue 'free'
#                    modal.modalTabs.forms.MyKites.inputs.callCount.show()
#                    modal.modalTabs.forms.MyKites.inputs.purchaseAmount.show()
#                  else
#                    modal.modalTabs.forms.MyKites.inputs.callCount.hide()
#                    modal.modalTabs.forms.MyKites.inputs.purchaseAmount.hide()
                nextElement :
                  callCount               :
                    itemClass             : KDSelectBox
                    cssClass              : "hidden callCount"
                    type                  : "select"
                    name                  : "type"
                    defaultValue          : 1000
                    selectOptions         : [
                      { title : "1K Call"   ,    value : 1000   }
                      { title : "10K Call"  ,    value : 10000  }
                      { title : "100K Call" ,    value : 100000 }
                    ]
                    nextElement               :
                      purchaseAmount          :
                        itemClass             : KDSelectBox
                        cssClass              : "hidden purchaseBox"
                        type                  : "select"
                        name                  : "type"
                        defaultValue          : 10
                        selectOptions         : [
                          { title : "$10" ,    value : 10 }
                          { title : "$30",     value : 30 }
                          { title : "$100",    value : 100 }
                        ]
              privacy                :
                label                : "Privacy"
                itemClass            : KDSelectBox
                type                 : "select"
                name                 : "privacy"
                defaultValue         : "private"
                tooltip              :
                  title              : "Public Kites are coming soon"
                  placement          : "right"
                selectOptions        : [
                  { title: "Private",               value: "private" }
                  { title: "Public - Coming Soon",  value: "public" }
                ]
                change        : ->
                  if @getValue() is "public"
                    @setValue 'private'
              description            :
                label                : "Description"
                itemClass            : KDInputView
                name                 : "description"
                placeholder          : "Description (optional)..."



  kiteNameCheckTimer = null

  kiteNameCheck:(input, event)->

    clearTimeout kiteNameCheckTimer

    input.setValidationResult "kiteNameCheck", null

    name = input.getValue()

    if input.valid
      kiteNameCheckTimer = setTimeout =>
        KD.remote.api.JKite.checkKiteName kiteName : name, (err, response)=>
          if err
            @notify err.message, "fail"
          else
            if response
              input.setValidationResult "usernameCheck", null
            else
              input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
      ,800

    return

class AccountMyKiteListItem extends KDListItemView
  constructor:(options,@data)->
    options = tagName : "li"
    options.cssClass = "my-kite-list-item"
    super options,data

  # viewAppended:->
  #   super
  #   @addSubView editLink = new KDCustomHTMLView
  #     tagName      : "a"
  #     partial      : "Delete This Kite"
  #     cssClass     : "action-link"

  # click:(event)->
  #   @emit "DeleteKiteSubmitted", @

  partial:(data)->

    @addSubView description  =  new KDLabelView
      title        : "Description"
      cssClass     : "main-label"

    @addSubView descriptionValue = new KDCustomHTMLView
      tagName      : "span"
      partial      : "#{data.description}"
      cssClass     : "static-text"

    @addSubView kiteName  =  new KDLabelView
      title        : "Kite Name"
      cssClass     : "main-label"

    @addSubView kiteNameValue = new KDCustomHTMLView
      tagName      : "span"
      partial      : "#{data.kiteName}"
      cssClass     : "static-text"

    @addSubView kiteKey  =  new KDLabelView
      title        : "Kite Key"
      cssClass     : "main-label"

    @addSubView kiteKeyValue = new KDCustomHTMLView
      tagName      : "span"
      partial      : "#{data.key}"
      cssClass     : "static-text"

    @addSubView status  =  new KDLabelView
      title        : "Status"
      cssClass     : "main-label"

    @addSubView statusValue = new KDCustomHTMLView
      tagName      : "span"
      partial      : "#{data.status}"
      cssClass     : "static-text"

    @addSubView privacy  =  new KDLabelView
      title        : "Privacy"
      cssClass     : "main-label"

    @addSubView privacyValue = new KDCustomHTMLView
      tagName      : "span"
      partial      : "#{data.privacy}"
      cssClass     : "static-text"

    @addSubView type  =  new KDLabelView
      title        : "Type"
      cssClass     : "main-label"

    @addSubView typeValue = new KDCustomHTMLView
      tagName      : "span"
      partial      : "#{data.type}"
      cssClass     : "static-text"
