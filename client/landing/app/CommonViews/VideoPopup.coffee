class VideoPopup extends KDView

# THIS NEEDS A DELEGATE

  constructor:(options,data)->
    super options,data
    @setClass "hidden invisible"
    @videoPopup = @getSingleton("windowController").videoPopup
    @embedData = data
    @options = options


  openVideoPopup:->
    h=@getDelegate().getHeight()
    w=@getDelegate().getWidth()
    t=@getDelegate().$().offset()
    @videoPopup?.close()

    popupUrl = "/1.0/video-container.html"

    @videoPopup = window.open popupUrl, "KodingVideo", "menubar=no,location=no,resizable=yes,titlebar=no,scrollbars=no,status=no,innerHeight=#{h},width=#{w},left=#{t.left+window.screenX},top=#{window.screenY+t.top+(window.outerHeight - window.innerHeight)}"
    @getSingleton("windowController").videoPopup = @videoPopup

    @utils.wait 1500, =>          # give the popup some time to open

      window.onfocus = =>         # once the user returns to the main view

        @utils.wait 500, =>       # user maybe just closed the popup

          if @videoPopup.length isnt 0

            window.onfocus = noop # reset the onfocus
            userChoice = no       # default selection is "Close the window"

            secondsToAutoClose = 10

            modal           = new KDModalView
              title         : "Do you want to keep the video running?"
              content       : "<p class='modal-video-close'>Your video will automatically end in <span class='countdown'>#{secondsToAutoClose}</span> seconds unless you click the 'Yes'-Button below.</p>"
              overlay       : yes
              buttons       :
                "No, close it" :
                  title     : "No, close it"
                  cssClass  : "modal-clean-gray"
                  callback  : =>
                    @videoPopup?.close()
                    modal.destroy()
                "Yes, keep it running" :
                  title     : "Yes, keep it running"
                  cssClass  : "modal-clean-green"
                  callback  : =>
                    modal.destroy()
                    userChoice = yes

            currentSeconds = secondsToAutoClose-1
            countdownInterval = window.setInterval =>
              modal.$("span.countdown").text currentSeconds--
            , 1000

            @utils.wait 1000*secondsToAutoClose, =>

              window.clearInterval countdownInterval

              unless userChoice
                @videoPopup?.close()
                modal.destroy()

      embed =
        embed : @embedData
        coordinates :
          left : @options.popup?.left or t.left+window.screenX or 100
          top : @options.popup?.top or window.screenY+t.top+(window.outerHeight - window.innerHeight) or 100
          # height : @options.popup?.height or h or 100
          # width : @options.popup?.width or w or 100

      if embed and @videoPopup
        @videoPopup.postMessage embed, "*"
      else @videoPopup?.close()