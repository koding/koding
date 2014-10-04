class PrivateMessageDeleteModal

  @create: (channel) ->

    removeFn = (modal) ->
      removeButton = modal.buttons['Remove']
      removeButton.showLoader()

      channelId = channel.getId()

      KD.remote.api.SocialChannel.delete {channelId}
        .then ->
          modal.destroy()
          KD.singletons.router.handleRoute '/Activity/Public'
        .catch (args...) ->
          KD.showError args...
          removeButton.hideLoader()

    modal = new KDModalView
      title      : 'Are you sure'
      content    : """
        <div class='modalformline'>
         <p>Delete this conversation?</p>
        </div>
        """
      overlay    : yes
      buttons    :
        Remove   :
          title  : 'Remove'
          style  : 'modal-clean-red'
          loader : { color: '#e94b35' }
          callback : -> removeFn modal
        Cancel   :
          title  : 'Cancel'
          style  : 'modal-cancel'
          callback : -> modal.destroy()

