{ uri }                   = require 'koding-config-manager'
async                     = require 'async'
encoder                   = require 'htmlencode'
{ createActivityContent } = require '../helpers'

createProfileFeed = (models, account, options, callback) ->
  { client, page, targetId } = options
  { SocialChannel } = models
  { sessionToken } = client
  targetId = account.socialApiId

  SocialChannel.fetchProfileFeedCount client, { targetId, sessionToken }, (err, response) ->
    return callback err  if err
    itemCount = response?.totalCount
    return callback null, ''  unless itemCount

    itemsPerPage = 5
    skip = 0
    if page > 0
      skip = (page - 1) * itemsPerPage

    fetchOptions = { targetId, limit: itemsPerPage, skip, replyLimit: 25 }

    SocialChannel.fetchProfileFeed client, fetchOptions, (err, result) ->
      return callback err  if err or not result
      unless result.length
        return callback null, ''

      index = yes  if result.length >= 3

      handleContent = handleContentKallback callback, {
        page         : page
        index        : index
        nickname     : account.profile.nickname
        itemCount    : itemCount
        itemsPerPage : itemsPerPage
      }

      buildContent models, result, options, handleContent


handleContentKallback = (callback, params) ->
  { page, itemCount, itemsPerPage, nickname, index } = params

  return (err, content) ->
    return callback err  if err

    return callback { message: 'content not found' }  if not content

    paginationOptions = {
      currentPage   : page
      numberOfItems : itemCount
      itemsPerPage
      route         : "#{nickname}"
    }

    pagination = getPagination paginationOptions
    if pagination
      content += "<nav class='crawler-pagination clearfix'>#{pagination}</nav>"

    callback null, { content, index }


createFeed = (models, options, callback) ->
  { JAccount, SocialChannel } = models
  { page, channelId, client, currentUrl
    route, contentType, channelName, sessionToken } = options

  return callback 'channelId not set'  unless channelId

  itemsPerPage = 20
  skip = 0
  if page > 0
    skip = (page - 1) * itemsPerPage

  options = {
    id          : channelId
    limit       : itemsPerPage
    skip        : skip
    channelName : channelName
    sessionToken
  }

  SocialChannel.fetchActivityCount { channelId, sessionToken }, (err, response) ->
    return callback err  if err
    itemCount = response?.totalCount
    return callback null, getEmptyPage channelName, currentUrl  unless itemCount

    options.replyLimit = 25
    SocialChannel.fetchActivities client, options, (err, result) ->
      return callback err  if err

      { messageList } = result
      return callback null, getEmptyPage channelName, currentUrl unless messageList?.length

      options.page = page
      buildContent models, result.messageList, options, (err, pageContent) ->
        return callback err  if err
        schemaorgTagsOpening = getSchemaOpeningTags contentType
        schemaorgTagsClosing = getSchemaClosingTags contentType
        channelTitleContent  = getChannelTitleContent channelName

        content = schemaorgTagsOpening + channelTitleContent +
          pageContent + schemaorgTagsClosing

        paginationOptions = {
          currentPage   : page
          numberOfItems : itemCount
          itemsPerPage
          route         : "Activity/#{route}"
        }

        pagination = getPagination paginationOptions
        fullPage = putContentIntoFullPage content, pagination, { index: yes }, currentUrl

        callback null, fullPage


getChannelTitleContent = (channelName) ->
  content = "<div class='logged-out channel-title'>##{channelName}</div>"


buildContent = (models, messageList, options, callback) ->
  { SocialChannel } = models
  { client, page } = options

  pageContent = ''
  queue = messageList.map (activity) -> (next) ->
    queue.pageContent or= ''

    createActivityContent models, activity, (err, content) ->
      if err
        console.error 'activity not listed', err
        return next()

      unless content
        # TODO Activity id can be added to error message
        console.error 'content not found'
        return next()

      pageContent = pageContent + content
      next()

  async.series queue, -> callback null, pageContent


getPagination = (options) ->
  # This is the number of adjacent link around current page.
  # E.g. let current page be 9, then pagination will look like this:
  # First Prev ... 4 5 6 7 8 9 10 11 12 13 14 ... Next Last
  # (Except 3-dots, they are useless for bots.)
  PAGERWINDOW = 4
  options.route ?= ''

  numberOfPages = Math.ceil(options.numberOfItems / options.itemsPerPage)
  firstLink = prevLink = nextLink = lastLink = ''

  if options.currentPage > 1
    firstLink = getSinglePageLink 1, 'First', options.route
    prevLink  = getSinglePageLink (options.currentPage - 1), 'Prev', options.route

  if options.currentPage < numberOfPages
    lastLink  = getSinglePageLink numberOfPages, 'Last', options.route
    nextLink  = getSinglePageLink (options.currentPage + 1), 'Next', options.route

  pagination = firstLink + prevLink

  start = 1
  end = numberOfPages

  start = options.currentPage - PAGERWINDOW  if options.currentPage > PAGERWINDOW

  if options.currentPage + PAGERWINDOW < numberOfPages
    end   = options.currentPage + PAGERWINDOW

  if start > 1
    pagination += getNoHrefLink ' ... '

  [start..end].map (pageNumber) ->
    pagination += getSinglePageLink pageNumber, null, options.route, options.currentPage

  if end < numberOfPages
    pagination += getNoHrefLink ' ... '

  pagination += nextLink
  pagination += lastLink

  return pagination

getNoHrefLink = (linkText) ->
  "<a href='#'>#{linkText}  </a>"

getSinglePageLink = (pageNumber, linkText = pageNumber, route, currentPage) ->
  currentPageClass = ''

  if currentPage is pageNumber
    currentPageClass = "class='activePage'"

  link = "<a href='#{uri.address}/#{route}?page=#{pageNumber}' #{currentPageClass}>#{linkText}  </a>"
  return link

appendDecoratedTopic = (tag, queue) ->
  queue.pageContent += createTagNode tag
  queue.next()

getSchemaOpeningTags = (contentType) ->
  openingTag = ''
  title = ''
  switch contentType
    when 'post'
      title = 'activities'
      openingTag += """<article itemscope itemtype='http://schema.org/BlogPosting'>"""
    when 'topic'
      title = 'topics'

  openingTag +=
    """
        <div itemscope itemtype="http://schema.org/ItemList">
          <meta itemprop="mainContentOfPage" content="true"/>
          <h2 itemprop="name" class="hidden">Latest #{title}</h2>
          <meta itemprop="itemListOrder" content="Descending" />
    """

  return openingTag

getSchemaClosingTags = (contentType) ->
  closingTag = '</div>'
  closingTag += '</article>'  if contentType is 'post'

  return closingTag

createTagNode = (tag) ->
  tagContent = ''
  return tagContent  unless tag.title
  """
  <div class="kdview kdlistitemview kdlistitemview-topics topic-item">
    <header>
      <h3 class="subview">
        <a href="#{uri.address}/Activity?tagged=#{tag.slug}">
          <span itemprop="itemListElement">#{tag.title}</span>
        </a>
      </h3>
    </header>
    <div class="stats">
      <a href="#"><span>#{tag.counts?.post ? 0}</span> Posts</a>
      <a href="#"><span>#{tag.counts?.followers ? 0}</span> Followers</a>
    </div>
    <article>#{encoder.XSSEncode(tag.body) ? ''}</article>
  </div>
  """

getSidebar = (currentUrl) ->
  redirectTo = if currentUrl then "?redirectTo=#{currentUrl}" else ''
  """
  <aside id="main-sidebar" class="static">
    <div class="logo-wrapper">
      <a href="/"><figure></figure></a>
    </div>
    <div class="kdcustomscrollview">
      <main class="kdview kdscrollview">
        <div class="activity-sidebar">
          <section class="followed topics">
            <h3 class="sidebar-title">Channels</h3>
            <a class="kdlistitemview-sidebar-item clearfix" href="/Activity/Public"><span class="ttag">public</span></a>
            <a class="kdlistitemview-sidebar-item clearfix" href="/Activity/Announcement/changelog"><span class="ttag">changelog</span></a>
          </section>
          <section class='sidebar-join'>
            Join our growing community of developers from all over the world who
            are building awesome applications on their full-featured, cloud-based
            development environment powered by Koding.
            <form action="/Register">
              <button type="submit" class="kdbutton solid green medium">
                <span class="button-title">Sign Up</span>
              </button>
            </form>
            <a href="/Login#{redirectTo}" class='login-link'>Login</a>
          </section>
          <section class='sidebar-bottom-links'>
            <a href='http://koding.com/Features'>Features</a>
            <a href='http://learn.koding.com/'>Koding University</a>
          </section>
        </div>
      </main>
    </div>
  </aside>
  """

getEmptyPage = (channelName, currentUrl) ->
  content  = getChannelTitleContent channelName
  content += "<div class='no-item-found'>There is no activity.</div>"

  putContentIntoFullPage content, '', null, currentUrl

putContentIntoFullPage = (content, pagination, graphMeta, currentUrl) ->
  getGraphMeta  = require './graphmeta'
  analytics     = require './analytics'

  graphMeta = getGraphMeta graphMeta

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    #{graphMeta}
  </head>
  <body itemscope itemtype="http://schema.org/WebPage" class="super activity">
    <div id="kdmaincontainer" class="kdview with-sidebar">
      #{getSidebar currentUrl}
      <section id="main-panel-wrapper" class="kdview">
        <div class="kdview kdtabpaneview activity clearfix content-area-pane active">
          <div id="content-page-activity" class="kdview content-page activity activity-pane clearfix">
            <main class="kdview kdscrollview kdtabview app-content">
              #{content}
              <nav class="crawler-pagination clearfix">
                #{pagination}
              </nav>
            </main>
          </div>
        </div>
      </section>
    </div>
    #{analytics()}
  </body>
  </html>
  """


module.exports = {
  buildContent
  createFeed
  createProfileFeed
  putContentIntoFullPage
  getSidebar
  getEmptyPage
}
