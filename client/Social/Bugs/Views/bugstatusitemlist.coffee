class BugStatusItemList extends StatusActivityItemView

  constructor:( options={}, data)->
    super options, data

    bugTags     = ["fixed", "postponed", "not repro","duplicate","by design"]
    @bugstatus  = new KDMultipleChoice
      cssClass     : "clean-gray editor-button control-button bug"
      labels       : bugTags
      multiple     : no
      defaultValue : "done"
      size         : "tiny"
      callback     : (value)=>
        KD.remote.api.JTag.fetchSystemTags {},limit:50, (err, systemTags)=>
          if err or systemTags.length < 1
            return new KDNotificationView
              title : err or "no system tag found."

          {body}     = data
          statusTags = data.tags
          newTags    = []

          #TODO : IF tag count of status is bigger, that become useless change to for loop
          tagToRemove = tag for tag in statusTags when tag.title in bugTags
          tagToAdd    = tag for tag in systemTags when tag.title is value
          return new KDNotificationView title: "Tag not found!" unless tagToAdd

          # if system tag exist, remove it then add new tag
          if tagToRemove
            index = statusTags.indexOf tagToRemove
            statusTags.splice index, 1
            # remove tag from body
            stringToRemove = "|#:JTag:#{tagToRemove.getId()}|"
            stringToAdd    = "|#:JTag:#{tagToAdd.getId()}|"
            body = body.replace stringToRemove, stringToAdd

            newTags.push id : tagToAdd.getId()
            newTags.push id:tag.getId() for tag in statusTags

            options  =
              body   : body
              meta   :
                tags : newTags

            data.modify options, (err)->
              log err if err

          else
            stringToAdd = "|#:JTag:#{tagToAdd.getId()}|"
            body       += " #{stringToAdd}"
            newTags.push id : tagToAdd.getId()
            newTags.push id:tag.getId() for tag in statusTags

            options  =
              body   : body
              meta   :
                tags : newTags

            data.modify options, (err)->
              log err if err

      KD.utils.defer =>
        @addSubView @bugstatus

  getItemDataId:-> @getData().getId?() or @getData().id or @getData()._id
  viewAppended: JView::viewAppended

