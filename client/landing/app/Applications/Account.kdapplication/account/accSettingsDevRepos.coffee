class AccountRepoListController extends KDListViewController
  constructor:->
    super
    @account = KD.whoami()
    list = @getListView()

  loadView:->
    super

    @loadItems =>
      @getListView().attachListeners()

    # @getView().parent.addSubView addButton = new KDButtonView
    #   style     : "clean-gray account-header-button"
    #   title     : ""
    #   icon      : yes
    #   iconOnly  : yes
    #   iconClass : "plus"
    #   callback  : ()=>
    #     @getListView().showAddEditModal null

  loadItems:(callback)->
    items = [
      { title : "Repositories are coming soon" }
    ]
    @instantiateListItems items

    # @account.fetchRepos (err,repos)=>
    #   log "repos:",repos
    #   @instantiateListItems repos
    #   callback?()

class AccountRepoList extends KDListView
  constructor:(options,data)->
    @account = KD.whoami()
    options = $.extend
      itemClass : AccountRepoListItem
    ,options
    super options,data

  loadItems:(callback)->
    @account.fetchRepos (err,repos)=>
      log "repos:",repos
      @instantiateListItems repos
      callback?()

  attachListeners:()->
    @items.forEach (item)=>
      item.getData().on "update",()->
        log "update event called:",item
        item.updatePartial item.partial item.getData()

  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview #{cssClass}'></ul>"

  showAddEditModal:(data,listItem)=>

    @_listItemToBeUpdated = listItem

    modal = @modal = new KDModalView
      title     : "Add a Repository"
      content   : ""
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : "auto"
      buttons   : yes

    modal.addSubView form = new KDFormView
      cssClass : "clearfix"
      callback : (formData)=>
        @updateRepo listItem, formData

    form.addSubView formline1 = new KDView cssClass : "modalformline"
    form.addSubView formline2 = new KDView cssClass : "modalformline"
    form.addSubView formline3 = new KDView cssClass : "modalformline"

    formline1.addSubView labelForType = new KDLabelView title : "Type:"
    formline2.addSubView labelForName = new KDLabelView title : "Name/Color:"
    formline3.addSubView labelForHost = new KDLabelView title : "URL:"

    formline1.addSubView inputForTypeSelection = new KDSelectBox
      type        : "select"
      label       : labelForType
      name        : "type"
      defaultValue: if data then data.type else "JRepoGit"
      selectOptions : [
        { title : "GIT", value : "JRepoGit" }
        { title : "SVN", value : "JRepoSvn" }
        { title : "HG",  value : "JRepoHg" }
      ]

    formline2.addSubView inputForName = new KDInputView
      label       : labelForName
      name        : "title"
      placeholder : "your repository name..."
      defaultValue: data.title if data

    formline2.addSubView inputForColorSelection = new KDSelectBox
      type        : "select"
      name        : "color"
      defaultValue: if data then data.color else "none"
      selectOptions : [
        { title : "No Color", value : "none"   }
        { title : "White",    value : "white"  }
        { title : "Red",      value : "red"    }
        { title : "Gray",     value : "gray"   }
        { title : "Orange",   value : "orange" }
        { title : "Yellow",   value : "yellow" }
        { title : "Green",    value : "green"  }
        { title : "Blue",     value : "blue"   }
        { title : "Purple",   value : "purple" }
      ]

    formline3.addSubView inputForHost = new KDInputView
      label       : labelForHost
      name        : "url"
      placeholder : "url//to.your.repo..."
      defaultValue: data.url if data

    if data
      form.addCustomData "operation","update"
      modal.createButton "Update", style : "modal-clean-gray", callback : form.submit
      modal.createButton "Delete", style : "modal-clean-red", callback : (event)=>
        form.addCustomData "operation","delete"
        form.submit(event)
    else
      form.addCustomData "operation","add"
      modal.createButton "Add", style : "modal-clean-gray", callback : form.submit

    modal.createButton "cancel",style : "modal-cancel", callback : @destroyModal
    modal.addSubView helpBox = new HelpBox, ".kdmodal-buttons"

  destroyModal:=>
    @modal.destroy()

  # API METHODS

  # loadItems:->
  #   @account.fetchRepositories (err,repositories)=>
  #     items ?= []
  #     for own repo in repositories
  #       item = mapBongoInstanceToView repo
  #       items.push item
  #     @instantiateListItems items
  # addRepo:=>
  #   log "ADD",arguments
  #
  #   @destroyModal()

  updateRepo:(listItem,formData)=>

    f = formData

    switch f.operation

      when "add"
        jr = new KD.remote.api[f.type]
          title : f.title
          url   : f.url
          color : f.color

        jr.save (err)=>
          unless err
            log "added"
            jr.type = f.type
            # @instantiateListItems [jr]
            itemView = new (@getOptions().itemClass ? KDListItemView) delegate:@,jr
            @addItemView itemView
          else
            log "failed to add.",err
      when "update"
        jr = listItem.getData()

        jr.title = f.title  ? jr.title
        jr.url   = f.url    ? jr.url
        jr.color = f.color  ? jr.color

        # log jr

        jr.update (err)->
          log "updated",err

      when "delete"
        jr = listItem.getData()
        jr.remove (err)=>
          unless err
            log "deleted succesfully"
            @removeListItem @_listItemToBeUpdated
          else
            log "failed to delete",err
    @destroyModal()

  # deleteRepo:=>
  #   log "DELETE","do your bongo stuff here"
  #   @destroyModal()








class AccountRepoListItem extends KDListItemView
  constructor:(options,data)->
    options = tagName : "li"
    super options,data

  click:(event)->
    # if @wasClickOn(".action-link") then @getDelegate().emit "ShowAddEditModal",@getData(),@
    if $(event.target).is ".action-link" then @getDelegate().showAddEditModal @getData(),@

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
  # partial:(data)->
  #   """
  #     <div class='labelish'>
  #       <span class='icon #{data.color}'></span>
  #       <span class='repo-title lightText'>#{data.title}</span>
  #     </div>
  #     <div class='swappableish swappable-wrapper posstatic'>
  #       <span class='blacktag'>#{data.type.substr(5)}</span>
  #       #{data.url}
  #       <!-- <cite class='small-text darkText'>last commit: #{data.lastCommitAt}</cite> -->
  #     </div>
  #     <a href='#' class='action-link'>Edit</a>
  #   """
































