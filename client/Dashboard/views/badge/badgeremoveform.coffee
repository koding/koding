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
                  return err if err
                  {itemList} = @getOptions()
                  itemList.destroy()
                  @destroy()
            Cancel          :
              title         : "No"
              style         : "modal-clean-red"
              type          : "cancel"
              callback      : =>
                @destroy()
    super options, data