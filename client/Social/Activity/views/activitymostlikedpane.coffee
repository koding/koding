class ActivityMostLikedContentPane extends ActivityContentPane

  viewAppended: ->
    super()

    KD.singletons.socialapi.on 'LikeDirty', =>
      @listController.removeAllItems()
      @isLoaded = no
