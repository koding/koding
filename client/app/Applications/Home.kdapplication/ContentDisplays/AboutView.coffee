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

  theTeam:
    [
        name      : 'Devrim Yasar'
        nickname  : 'devrim'
        job       : 'Co-Founder &amp; CEO'
        image     : '../images/people/devrim.jpg'
      ,
        name      : 'Sinan Yasar'
        nickname  : 'sinan'
        job       : 'Co-Founder &amp; Chief UI Engineer'
        image     : '../images/people/sinan.jpg'
      ,
        name      : 'Chris Thorn (w/ Milo)'
        nickname  : 'chris'
        job       : 'Director of Engineering'
        image     : '../images/people/chris.jpg'
      ,
        name      : 'Gökmen Göksel'
        nickname  : 'gokmen'
        job       : 'Software Engineer'
        image     : '../images/people/gokmen.jpg'
      ,
        name      : 'Arvid Kahl'
        nickname  : 'arvidkahl'
        job       : 'Software Engineer'
        image     : '../images/people/arvid.jpg'
      ,
        name      : 'Richard Musiol'
        nickname  : 'neelance'
        job       : 'Software Engineer'
        image     : '../images/people/richard.jpg'
      ,
        name      : 'Chris Nelson Blum'
        nickname  : 'blum'
        job       : 'System Administrator'
        image     : '../images/people/nelson.jpg'
      ,
        name      : 'Bahadir Kandemir'
        nickname  : 'bahadir'
        job       : 'Software Engineer'
        image     : '../images/people/bahadir.jpg'
      ,
        name      : 'Fatih Arslan'
        nickname  : 'arslan'
        job       : 'Software Engineer'
        image     : '../images/people/arslan.jpg'
      ,
        name      : 'Fatih Acet'
        nickname  : 'fatihacet'
        job       : 'Front-End Developer'
        image     : '../images/people/acet.jpg'
      ,
        name      : 'Fatih Kadir Akin'
        nickname  : 'fkadev'
        job       : 'Software Engineer'
        image     : '../images/people/fka.jpg'
      ,
        name      : 'Senthil Arivudainambi'
        nickname  : 'sent-hil'
        job       : 'Software Engineer'
        image     : '../images/people/senthil.jpg'
      ,
        name      : 'Armagan Kimyonoglu'
        nickname  : 'armagan'
        job       : 'Software Engineer'
        image     : '../images/people/armagan.jpg'
      ,
        name      : 'Cihangir Savas'
        nickname  : 'siesta'
        job       : 'Software Engineer'
        image     : '../images/people/cihangir.jpg'
      ,
        name      : 'Halil Köklü'
        nickname  : 'halk'
        job       : 'Software Engineer'
        image     : '../images/people/halk.jpg'
      ,
        name      : 'Geraint Jones'
        nickname  : 'geraint'
        job       : 'System Administrator'
        image     : '../images/people/geraint.jpg'
      ,
        name      : 'Aybars Badur'
        nickname  : 'ybrs'
        job       : 'Software Engineer'
        image     : '../images/people/aybars.jpg'
      ,
        name      : 'Erdinc Akkaya'
        nickname  : 'ybrs'
        job       : 'Software Engineer'
        image     : '../images/people/erdinc.jpg'
      ,
        name      : 'Nicole Bacon'
        nickname  : 'bacon'
        job       : 'XEO &amp; Office Manager &amp; Mom'
        image     : '../images/people/nicole.jpg'
     # ,
     #   name      : 'Aleksey Mykhailov'
     #   nickname  : 'aleksey-m'
     #   job       : 'Sys Admin &amp; node.js Developer'
     #   image     : '../images/people/aleksey.jpg'
     #  ,
     #    name      : 'Son Tran-Nguyen'
     #    nickname  : 'sntran'
     #    job       : 'Software Engineer'
     #    image     : '../images/people/son.jpg'
    ]


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










