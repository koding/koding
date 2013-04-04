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
      style     : "clean-gray account-header-button"
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

    list.on "UpdateKiteSubmitted", @bound "updateDatabase"

    list.on "CreateKiteSubmitted", @bound "createKite"

    @on "KiteDeleted", list.bound "removeItem"

    @on "KiteUpdated", list.bound ""

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
                    <p><label>Status    :  </label> <b>#{itemData.status}</b></p>
                    <p><label>Privacy   :  </label> <b>#{itemData.privacy}</b></p>
                    <p><label>Type      :  </label> <b>#{itemData.type}</b></p>
                  </div>
                  """

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
    {description, kiteName, privacy, type} = form.modal.modalTabs.forms.MyKites.inputs

    KD.remote.api.JKite.create
      description  : description.getValue()
      kiteName     : kiteName.getValue()
      privacy      : privacy.getValue()
      type         : type.getValue()
    ,(err, kite) =>
      if err
        @notify err.message, "fail"
        form.modal.modalTabs.forms.MyKites.buttons.Create.hideLoader()
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
              @modal.modalTabs.forms.MyKites.buttons.Create.showLoader()
              @emit "CreateKiteSubmitted", @
            buttons                   :
              create                  :
                title                 : "Create"
                style                 : "modal-clean-gray"
                type                  : "submit"
                loader                :
                  color               : "#444444"
                  diameter            : 12
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
                type                  : "select"
                name                  : "type"
                defaultValue          : "free"
                selectOptions         : [
                  { title : "Free",    value : "free" }
                  { title : "Paid",    value : "paid" }
                ]
              privacy                :
                label                : "Privacy"
                itemClass            : KDSelectBox
                type                 : "select"
                name                 : "privacy"
                defaultValue         : "public"
                selectOptions        : [
                  { title: "Public", value: "public" }
                  { title: "Private", value: "private" }
                ]
              description            :
                label                : "Description"
                itemClass            : KDInputView
                name                 : "description"
                placeholder          : "Description (optional)..."



  kiteNameCheckTimer = null

  kiteNameCheck:(input, event)->

    if event then console.log event

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
#    if input.valid
#      KD.remote.api.JKite.checkKiteName kiteName : name, (err, response)=>
#        if err
#          @notify err.message, "fail"
#        else
#          if response
#            input.setValidationResult "kiteNameCheck", null
#          else
#            input.valid = false
#            input.setValidationResult "kiteNameCheck", "Sorry, \"#{name}\" is already taken!"

    return

class AccountMyKiteListItem extends KDListItemView
  constructor:(options,@data)->
    options = tagName : "li"
    options.cssClass = "my-kite-list-item"
    super options,data

  # viewAppended:()->
  #   super
  #   @addSubView editLink = new KDCustomHTMLView
  #     tagName      : "a"
  #     partial      : "Delete This Kite"
  #     cssClass     : "action-link"

  # click:(event)->
  #   @emit "DeleteKiteSubmitted", @

  partial:(data)->
    """
      <div class='kite-item'>
        <div class='description'>
          <span class='label'>Description:</span>
          <span class='value'>#{data.description}</span>
        </div>
        <div class='kiteName'>
          <span class='label'>Used Kite Name:</span>
          <span class='value'>#{data.kiteName}</span>
        </div>
        <div class='kiteKey'>
        <span class='label'>Kite Key:</span>
        <span class='value'>#{data.key}</span>
        </div>
        <div class='status'>
          <span class='label'>Status:</span>
          <span class='value'>#{data.status}</span>
        </div>
        <div class='privacy'>
          <span class='label'>Privacy:</span>
          <span class='value'>#{data.privacy}</span>
        </div>
        <div class='type'>
          <span class='label'>Type:</span>
          <span class='value'>#{data.type}</span>
        </div>
      </div>
    """
