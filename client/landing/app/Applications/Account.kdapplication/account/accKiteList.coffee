class AccountKiteListController extends KDListViewController

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
        width   : 500
        overlay : yes
        content : """
                  <div class='modalformline'>
                    <p><label>Kite Application Name:  </label> <i>#{itemData.appName}</i></p>
                    <p><label>Kite Name            :  </label> <i>#{itemData.kiteName}</i></p>
                    <p><label>Kite Key             :  </label> <b>#{itemData.key}</b></p>
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
    data = form.getData()
    KD.remote.api.JKite.create
      appName   : data.kiteAppName
      kiteName  : data.kiteName
      count     : data.kiteCallLimit 
      (err, kite) => 
        if err
          @notify err.message, "fail"
        else
          @notify 'Your kite is created', "success"
          @emit "KiteCreated", kite
          form.parent.destroy()
          
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
    form = new AccountAddKiteForm
      callback : @formSubmit
      cssClass : "clearfix"

    modal = new KDModalView
      title     : "Add a new kite"
      content   : ""
      overlay   : yes
      cssClass  : "kite-kdmodal"
      width     : 500
      height    : 233
      view      : form
      buttons   :
        "Create New Kite" :
          style     : "modal-clean-gray"
          callback  : => @emit "CreateKiteSubmitted", form
        Cancel   :
          style     : "modal-cancel"
          callback  : (event)->
            form.destroy()
            modal.destroy()

class AccountAddKiteForm extends KDFormView
  viewAppended:->
    super
    @addSubView kiteAppNameView  = new KDView
      cssClass : "modalformline"
    kiteAppNameView.addSubView kiteAppName  = new KDInputView name : "kiteAppName", placeholder : "Your app name..."

    @addSubView kiteNameView  = new KDView
      cssClass : "modalformline"
    kiteNameView.addSubView kiteName  = new KDInputView name : "kiteName", placeholder : "Kite name..."

    @addSubView kiteApiCallLimitView  = new KDView
      cssClass : "modalformline"
    kiteApiCallLimitView.addSubView kiteApiCallLimit = new KDInputView name : "kiteCallLimit", placeholder : "Kite Api Call limit..."


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
        <div class='appName'>
          <span class='label'>Application Name:</span>
          <span class='value'>#{data.appName}</span>
        </div>
        <div class='kiteName'>    
          <span class='label'>Used Kite Name:</span>
          <span class='value'>#{data.kiteName}</span>
        </div>
        <div class='kiteKey'> 
          <span class='label'>Kite Key:</span>
          <span class='value'>#{data.key}</span>
        </div>
      </div>
    """