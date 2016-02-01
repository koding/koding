CustomLinkView   = require './../core/customlinkview'
HomeRegisterForm = require './registerform'

TWEET_TEXT       = 'I\'ve applied for the world\'s first global virtual #hackathon by @koding. Join my team!'
SHARE_URL        = 'http://koding.com/Hackathon2014'

VIDEO_URL        = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.webm'
VIDEO_URL_MP4    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.mp4'
VIDEO_URL_OGG    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.ogv'

DAYS             = ['SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY']
MONTHS           = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER']

{
  judges   : JUDGES
  partners : PARTNERS
} = KD.campaignStats.campaign

module.exports = class HomeView extends KDView

  getStats = ->

    KD.campaignStats ?=
      campaign           :
        cap              : 50000
        prize            : 10000
      totalApplicants    : 34512
      approvedApplicants : 12521
      isApplicant        : no
      isApproved         : no
      isWinner           : no

  constructor: (options = {}, data)->

    options.bind = 'mousemove'

    super options, data

    @logosBeingDragged = no

    @setPartial @partial()


  updateWidget : ->

    @updateStats()


  viewAppended : ->

    super

    @logos = new KDCustomHTMLView
      cssClass  : 'logos'
      tagName   : 'figure'
      bind      : 'mousemove mouseleave mouseenter'
      partial    : """
        <i class="odesk"></i>
        <i class="kissmetrics"></i>
        <i class="accel"></i>
        <i class="udemy"></i>
        <i class="aws"></i>
        <i class="tutum"></i>
        <i class="code"></i>
        <i class="facebook"></i>
        <i class="atlassian"></i>
        <i class="iron"></i>
        <i class="turkcell"></i>
        <i class="digitalocean"></i>
        <i class="deviantart"></i>
        <i class="baincapital"></i>
        <i class="eniac"></i>
      """

    logosTitle = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'logos-title'
      partial  : 'with some amazing judges from:'
    @addSubView logosTitle, 'section.introduction'
    @addSubView @logos, 'section.introduction'


    video = document.getElementById 'bgVideo'
    if window.innerWidth < 680
      video.parentNode.removeChild video
    else
      video.addEventListener 'loadedmetadata', ->
        @currentTime = 8
        @playbackRate = .7
        KD.utils.wait 3000, -> video.classList.add 'in'
      , no

  mouseMove: (event) ->

    yPos   = event.clientY + window.scrollY
    height = @$('section.introduction').outerHeight()

    if height - 250 < yPos < height + 50
    then @mouseEnter()
    else return @mouseLeave()

    ww        = window.innerWidth
    width     = @logos.getWidth()
    slideable = width - ww
    margin    = -(width / 2)
    percent   = event.clientX / ww
    slide     = slideable * percent
    newMargin = (margin + (slideable / 2)) - slide

    @logos.setCss 'margin-left', "#{newMargin}px"


  mouseLeave: ->

    return  unless @logosBeingDragged

    @logosBeingDragged = no
    @logos.unsetClass 'no-anim'
    @logos.setCss 'margin-left', '-1400px'


  mouseEnter: do ->
    waiting = no
    ->
      return  if waiting or @logosBeingDragged
      waiting = yes
      KD.utils.wait 300, =>
        waiting = no
        @logosBeingDragged = yes
        @logos.setClass 'no-anim'


  updateStats: -> @$('div.counters').html @getStats()

  getStats: ->

    { totalApplicants, approvedApplicants, campaign } = getStats()
    { cap, prize } = campaign

    return """
      PRIZE: <span>$#{prize.toLocaleString()}</span>
      TOTAL SLOTS: <span>#{cap.toLocaleString()}</span>
      APPLICATIONS RECEIVED: <span>#{totalApplicants.toLocaleString()}</span>
      APPROVED APPLICANTS: <span>#{approvedApplicants.toLocaleString()}</span>
      """

  partial: ->

    dateString = KD.campaignStats?.campaign?.startDate or 'Mon Oct 27 2014 10:00:00 GMT-0700 (PDT)'
    startDate  = new Date dateString

    day      = DAYS[startDate.getDay()]
    month    = MONTHS[startDate.getMonth()]
    date     = startDate.getDate()
    year     = startDate.getYear() + 1900
    hour     = startDate.getHours()
    minutes  = startDate.getMinutes()
    minutes  = if minutes < 10 then "0#{minutes}" else minutes
    meridiem = if hour > 12 then 'PM' else 'AM'

    niceDate = "#{day} #{month} #{date} #{year} #{hour}:#{minutes}#{meridiem}"

    """
    <section class="introduction">
      <video id="bgVideo" autoplay loop muted>
        <source src="#{VIDEO_URL}" type="video/webm"; codecs=vp8,vorbis">
        <source src="#{VIDEO_URL_OGG}" type="video/ogg"; codecs=theora,vorbis">
        <source src="#{VIDEO_URL_MP4}">
      </video>
      <h1>ANNOUNCING THE WORLD’S FIRST GLOBAL VIRTUAL <span>#HACKATHON</span></h1>
      <h3>Let's hack together, no matter where we are!</h3>
      <h3>APPLICATIONS OPEN ON #{niceDate}</h3>
    </section>
    <div class="counters">#{@getStats()}</div>
    """
