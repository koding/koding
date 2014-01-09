class AboutView extends JView

  AudioContext = null
  context      = null
  march        = null
  marchURL     = "/techno.wav"
  marchURL     = "/star-wars.m4a"
  marchBuffer  = null
  onError      = (err)-> error err

  init = ->
    try
      # Fix up for prefixing
      AudioContext = window.AudioContext or window.webkitAudioContext
      context      = new AudioContext()
      loadSound marchURL, (buffer)->
        march = play buffer

    catch err
      log 'Web Audio API is not supported in this browser'

  loadSound = (url, callback)->
    request = new XMLHttpRequest()
    request.open 'GET', url, yes
    request.responseType = 'arraybuffer'
    request.onload = ->
      context.decodeAudioData request.response, (buffer)->
        callback buffer
      , onError
    request.send()

  play = (buffer, time=0)->
    source        = context.createBufferSource()
    source.buffer = buffer
    source.loop   = yes
    source.connect context.destination
    source.start time
    return source

  stop = (source)->
    source.stop = source.noteOff unless source.stop
    source.stop 0

  constructor:(options = {}, data)->

    options.cssClass = "about"

    super options, data
    # @utils.wait 6000, init
    # @on 'KDObjectWillBeDestroyed', -> stop march  if march

  viewAppended:->

    super
    @putTeam()

  pistachio:->

    """
      <figure></figure>
      <div class='perspective'>
        <div class='wrapper'>
          <div class='bio'>
            <h2>About Koding</h2>
            <p>coming soon</p>
            <h2>Let's be free</h2>
            <p>coming soon</p>
          </div>
          <div class="team"></div>
          <div>
            <p>
              We're located in the <strong>SOMA</strong> district of <strong>San Francisco, California.</strong>
            </p>
            <address>
              <strong>Koding, Inc.</strong>
              <a href="http://goo.gl/maps/XGWr" target="_blank">
                358 Brannan<br>
                San Francisco, CA 94107
              </a>
            </address>
          </div>
        </div>
      </div>
    """

  putTeam:->

    for memberData in @theTeam
      member = new AboutMemberView {}, memberData
      @addSubView member, ".team"


class AboutMemberView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'teammember'

    super options, data

    # @memberLink = new ProfileLinkView null, null

  viewAppended: JView::viewAppended

  pistachio:->

    {name, job, image, nickname} = @getData()

    """
      <img src="#{image}" />
      <p>
        <a href='/#{nickname}'><strong>#{name}</strong></a>
        #{job}
      </p>
    """










