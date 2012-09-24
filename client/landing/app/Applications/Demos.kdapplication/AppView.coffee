class DemosMainView extends KDScrollView

  viewAppended:()->

    # @addSubView split = new SlidingSplit
    #   type            : "horizontal"
    #   cssClass        : "chat-split"
    #   sizes           : [null]
    #   scrollContainer : @

    mainView     = @

    @addSubView tokenInput = new KDTokenizedInput
      match         :
        topic       : 
          regex     : /\B#\w.*/
          # throttle  : 2000
          dataSource: (token)->
            appManager.tell "Topics", "fetchSomeTopics", selector : token.slice(1), (err, topics)->
              log err, topics
              if not err and topics.length > 0
                tokenInput.showMenu {token, rule : "topic"}, topics
          callback  : (token, data)->
            log token, data, "edit input"
            val = tokenInput.input.getValue()
            val = val.replace token, "#{data.title}"
            {input, layer, menu} = tokenInput
            input.setValue val
            layer.updatePartial layer.$().html().replace data.title, "<span>#{data.title}</span>"
            menu.destroy()
            input.setFocus()

        # username    :
        #   regex     : /\B@\w.+/
        #   # throttle  : 2000
        #   callback  : (token)->
        #     log token, "member"
        #     appManager.tell "Members", "fetchSomeMembers", selector : token.slice(1), (err, members)->
        #       log err, members
        #       if not err and members.length > 0
        #         tokenInput.showMenu {token}, members
