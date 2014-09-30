class PrivateMessageDeleteModal

  @create: (channel) ->

    modal         = KDModalView.confirm
      title       : 'Are you sure?'
      description : 'Delete this conversation?'
      ok          :
        title     : 'Remove'
        callback  : ->

          modal.destroy()

          channelId = channel.getId()

          KD.remote.api.SocialChannel.delete {channelId}
            .catch KD.showError
