class ActivityMostLikedContentPane extends ActivityContentPane

  viewAppended: ->
    super()

    KD.singletons.socialapi.on 'LikeDirty', =>
      console.log 'like dirty'
      @listController.removeAllItems()
      @isLoaded = no