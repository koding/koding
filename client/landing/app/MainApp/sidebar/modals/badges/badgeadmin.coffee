class BadgeAdmin extends JView

  constructor: (options = {}, data) ->
    super options, data

    @container = new KDView
      cssClass : "badge-admin-dashboard"

    @listController = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-list"
        itemClass         : BadgeListItem

    @addNewBadgeForm()
    @listAllTheBadges()

  viewAppended: ->
    super

  listAllTheBadges: ->
    {parentView} = @getOptions()
    @container.addSubView @listController.getView()
    parentView.addSubView @container

    KD.remote.api.JBadge.listBadges '',(err, badges)=>
      return callback err if err
      @listController.instantiateListItems badges

  addNewBadgeForm:->
    badgeForm = new KDFormViewWithFields
      title             : "Add New Badge"
      buttons           :
        Add             :
          title         : "Add"
          style         : "modal-clean-green"
          type          : "submit"
        Cancel          :
          title         : "Cancel"
          style         : "modal-clean-red"
      callback          : (formData)=>
        log formData,"new badge submitted"
        KD.remote.api.JBadge.create formData, (err, badge) =>
          @listController.addItem badge
      fields            :
        Title           :
          label         : "Title"
          type          : "text"
          name          : "title"
          placeholder   : "enter the name of the badge"
          validate      :
            rules       :
              required  : yes
            messages    :
              required  : "add badge name"
        Icon            :
          label         : "Badge Icon"
          type          : "text"
          name          : "iconURL"
          placeholder   : "write path to icon"
          validate      :
            rules       :
              required  : yes
            messages    :
              required  : "add badge icon"
        Reward          :
          label         : "Reward"
          type          : "text"
          name          : "reward"
          placeholder   : "reward of badge"
        Rule            :
          label         : "Rule"
          type          : "text"
          name          : "rule"
          placeholder   : "when this badge will be gained"
        Description     :
          label         : "Description"
          type          : "text"
          name          : "description"
          placeholder   : "Description of the badge to be showed to user"
    @container.addSubView badgeForm
