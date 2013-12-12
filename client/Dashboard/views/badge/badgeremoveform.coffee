class BadgeRemoveForm extends KDModalViewWithForms
  constructor:(options = {}, data)->
    options.title           or= 'Sure ?'
    options.tabs            ?=
      forms                 :
        deleteForm          :
          buttons           :
            yes             :
              title         : "YES"
              style         : "modal-clean-green"
              type          : "submit"
              callback      : =>
                {badge}     = @getData()
                badge.deleteBadge (err)=>
                  {itemList} = @getOptions()
                  updateForm = @getOptions().delegate
                  updateForm.badgeForm.destroy()
                  itemList.destroy()
                  @destroy()
                  return err if err
            Cancel          :
              title         : "No"
              style         : "modal-clean-red"
              type          : "cancel"
              callback      : =>
                @destroy()
    super options, data