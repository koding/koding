class TeamworkShareModal extends KDModalView

  constructor: (options = {}, data) ->

    url = "#{location.origin}/Teamwork?sessionKey=#{options.delegate.sessionKey}"
    message =
      """
      <div class='modalformline'>
        <p>Share the url below to invite others to your Koding teamwork/pair coding session.</p><br />
        <p>
          Be aware that makes your VM accessible to your collaborators until you close the browser tab.
        </p><br />

        <p>
          <a href="#{url}">#{url}</a>
        </p>
      </div>
      """

    options.cssClass = "tw-modal tw-share-modal"
    options.overlay  = yes
    options.width    = 655
    options.overlay  = yes
    options.title    = "Collaborate in real-time"
    options.cssClass = "new-kdmodal"
    options.content  = "<div class='modalformline'>#{message}</div>"
    options.buttons  =
      Close          :
        callback     : => @destroy()

    super options, data
