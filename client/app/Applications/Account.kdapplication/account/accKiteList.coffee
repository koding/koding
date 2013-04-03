class AccountKiteListController extends KDListViewController

  constructor:(options,data)->
    options.cssClass = "kites"
    super options,data

  loadView:->
    super

    KD.remote.api.JMemberKite.fetchAll {}, (err, kites) =>
      if err then warn err
      else 
        @instantiateListItems kites

    list = @getListView()
    @getView().parent.addSubView addKiteButton = new KDButtonView
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
                  </div>
                  """

  deleteKite:(listItem)->
    data = listItem.getData()
    KD.remote.api.JKite.get
      id   : data.id
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
    {description, callCount, kites} = form.modal.modalTabs.forms.Kites.inputs

    KD.remote.api.JMemberKite.create
      description  : description.getValue()
      callCount    : callCount.getValue()
      kites        : kites.getValue()
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


class AccountKiteList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName   : "ul"
      itemClass : AccountKiteListItem
    ,options
    super options,data
  showModal:->
    modal = @modal = new KDModalViewWithForms
      title                   : "Create a third party kite"
      content                 : ""
      overlay                 : yes
      cssClass                : "new-kdmodal"
      width                   : 500
      height                  : "auto"
      tabs                    :
        forms                 :
          Kites               :
            callback          : =>
              @modal.modalTabs.forms.Kites.buttons.Create.showLoader()
              @emit "CreateKiteSubmitted", @
            buttons           :
              create          :
                title         : "Create"
                style         : "modal-clean-gray"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : -> @hideLoader()
              cancel          :
                title         : "Cancel"
                style         : "modal-cancel"
                callback      : (event)-> modal.destroy()
            fields            :
              description     :
                label         : "Description"
                itemClass     : KDInputView
                name          : "description"
                placeholder   : "Description (optional)..."
              callCount       :
                label         : "API Call Count"
                itemClass     : KDInputView
                name          : "apiCallCount"
                placeholder   : "100"
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : "Only numbers for Api Call Count"
              kites           :
                label         : "Select a kite"
                itemClass     : KDSelectBox
                type          : "select"
                name          : "kite"
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "You must select a Kite!"
                selectOptions : (cb)->
                  KD.remote.api.JKite.fetchKites {}, (err, kites) =>
                    if err then warn err
                    else
                      options = ( title : kite.kiteName, value : kite._id for kite in kites)
                      cb options

class AccountKiteListItem extends KDListItemView
  constructor:(options,@data)->
    options = tagName : "li"
    options.cssClass = "kite-list-item"
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
        <div class='kiteKey'> 
          <span class='label'>Kite Key:</span>
          <span class='value'>#{data.key}</span>
        </div>
      </div>
    """