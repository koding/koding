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
    @utils.wait 6000, init
    @on 'KDObjectWillBeDestroyed', -> stop march  if march

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
            <p>Chuck ipsum. Chuck Norris built a time machine and went back in time to stop the JFK assassination. As Oswald shot, Chuck Norris met all three bullets with his beard, deflecting them. JFK's head exploded out of sheer amazement. Chuck Norris built a time machine and went back in time to stop the JFK assassination. As Oswald shot, Chuck Norris met all three bullets with his beard, deflecting them. JFK's head exploded out of sheer amazement. If you have five dollars and Chuck Norris has five dollars, Chuck Norris has more money than you. Chuck Norris found out about Conan O'Brien's lever that shows clips from "Walker: Texas Ranger" and is working on a way to make it show clips of Norris having sex with Conan's wife. Chuck Norris built a time machine and went back in time to stop the JFK assassination. As Oswald shot, Chuck Norris met all three bullets with his beard, deflecting them. JFK's head exploded out of sheer amazement. There is no chin behind Chuck Norris' beard. There is only another fist. When observing a Chuck Norris roundhouse kick in slow motion, one finds that Chuck Norris actually rapes his victim in the ass, smokes a cigarette with Dennis Leary, and then roundhouse kicks them in the face. Chuck Norris used live ammunition during all shoot-outs. When a director once said he couldn’t, he replied, “Of course I can, I’m Chuck Norris,” and roundhouse kicked him in the face.  After much debate, President Truman decided to drop the atomic bomb on Hiroshima rather than the alternative of sending Chuck Norris. It was more "humane". Chuck Norris does not use spell check. If he happens to misspell a word, Oxford will simply change the actual spelling of it.  Although it is not common knowledge, there are actually three sides to the Force: the light side, the dark side, and Chuck Norris. Chuck Norris doesn't see dead people. He makes people dead. Chuck Norris once tried to wear glasses. The result was him seeing around the world to the point where he was looking at the back of his own head. A Handicap parking sign does not signify that this spot is for handicapped people. It is actually in fact a warning, that the spot belongs to Chuck Norris and that you will be handicapped if you park there. Chuck Norris is Luke Skywalker’s real father. Chuck Norris once kicked a baby elephant into puberty. If you want a list of Chuck Norris’ enemies, just check the extinct species list.  Chuck Norris' evil twin brother, Richard Simmons, once approached Chuck with the hope of reconciliation, but at the sight of Richard's curly, well kept hair, Chuck Norris became so enraged that he turned green with hate and ripped Richard Simmons arms and legs off. This action was the origin of the Marvel Comic badass, The Incredible Hulk. </p>
            <h2>Let's be free</h2>
            <p>When observing a Chuck Norris roundhouse kick in slow motion, one finds that Chuck Norris actually rapes his victim in the ass, smokes a cigarette with Dennis Leary, and then roundhouse kicks them in the face.Chuck Norris sent Jesus a birthday card on December 25th and it wasn't Jesus’ birthday. Jesus was to scared to correct Chuck Norris and to this day December 25th is known as Jesus' birthday.Chuck Norris doesn’t believe in Germany. Chuck Norris once tried to defeat Garry Kasparov in a game of chess. When Norris lost, he won in life by roundhouse kicking Kasparov in the side of the face. Chuck Norris isn’t lactose intolerant. He just doesn’t put up with lactose’s sh*t. Chuck Norris does not hunt because the word hunting infers the probability of failure. Chuck Norris goes killing.A blind man once stepped on Chuck Norris' shoe. Chuck replied, "Don't you know who I am? I'm Chuck Norris!" The mere mention of his name cured this man blindness. Sadly the first, last, and only thing this man ever saw, was a fatal roundhouse delivered by Chuck Norris.Scientists used to believe that diamond was the world’s hardest substance. But then they met Chuck Norris, who gave them a roundhouse kick to the face so hard, and with so much heat and pressure, that the scientists turned into artificial Chuck Norris. Chuck Norris sleeps with a night light. Not because Chuck Norris is afraid of the dark, but the dark is afraid of Chuck NorrisChuck Norris once tried to defeat Garry Kasparov in a game of chess. When Norris lost, he won in life by roundhouse kicking Kasparov in the side of the face. Chuck Norris does not procreate, he breedsAfter much debate, President Truman decided to drop the atomic bomb on Hiroshima rather than the alternative of sending Chuck Norris. It was more "humane".Ironically, Chuck Norris’ hidden talent is invisibility. When Chuck Norris had surgery, the anesthesia was applied to the doctors.Chuck Norris is what Willis was talking about</p>
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










