{argv}                  = require 'optimist'
{uri}                   = require('koding-config-manager').load("main.#{argv.c}")
{daisy}                 = require "bongo"
encoder                 = require 'htmlencode'
{createActivityContent} = require '../helpers'

ITEMSPERPAGE = 20

createFeed = (models, options, callback)->
  {JAccount, SocialChannel} = models
  {page, channelId, client, route, contentType} = options

  return callback "channelId not set"  unless channelId

  skip = 0
  if page > 0
    skip = (page - 1) * ITEMSPERPAGE

  options = {
    id    : channelId
    limit : ITEMSPERPAGE
    skip  : skip
  }

  SocialChannel.fetchActivityCount {channelId}, (err, response)->
    return callback err  if err
    itemCount = response?.totalCount
    return callback null, getEmptyPage()  unless itemCount

    options.replyLimit = 25
    SocialChannel.fetchActivities client, options, (err, result) ->
      return callback err  if err

      {messageList} = result
      return callback null, getEmptyPage() unless messageList?.length

      options.page = page
      buildContent models, result.messageList, options, (err, pageContent) ->
        return callback err  if err
        schemaorgTagsOpening = getSchemaOpeningTags contentType
        schemaorgTagsClosing = getSchemaClosingTags contentType

        content = schemaorgTagsOpening + pageContent + schemaorgTagsClosing

        pagination = getPagination page, itemCount, "Activity/#{route}"
        fullPage = putContentIntoFullPage content, pagination

        callback null, fullPage


buildContent = (models, messageList, options, callback) ->
  {SocialChannel} = models
  {client, page} = options

  pageContent = ""
  queue = messageList.map (activity)->->
    queue.pageContent or= ""

    createActivityContent models, activity, (err, content)->
      if err
        console.error "activity not listed", err
        return queue.next()

      unless content
        # TODO Activity id can be added to error message
        console.error "content not found"
        return queue.next()

      pageContent = pageContent + content
      queue.next()

  queue.push ->
    callback null, pageContent

  daisy queue


getPagination = (currentPage, numberOfItems, route="")->
  # This is the number of adjacent link around current page.
  # E.g. let current page be 9, then pagination will look like this:
  # First Prev ... 4 5 6 7 8 9 10 11 12 13 14 ... Next Last
  # (Except 3-dots, they are useless for bots.)
  PAGERWINDOW = 4

  numberOfPages = Math.ceil(numberOfItems / ITEMSPERPAGE)
  firstLink = prevLink = nextLink = lastLink = ""

  if currentPage > 1
    firstLink = getSinglePageLink 1, "First", route
    prevLink  = getSinglePageLink (currentPage - 1), "Prev", route

  if currentPage < numberOfPages
    lastLink  = getSinglePageLink numberOfPages, "Last", route
    nextLink  = getSinglePageLink (currentPage + 1), "Next", route

  pagination = firstLink + prevLink

  start = 1
  end = numberOfPages

  start = currentPage - PAGERWINDOW  if currentPage > PAGERWINDOW

  if currentPage + PAGERWINDOW < numberOfPages
    end   = currentPage + PAGERWINDOW

  if start > 1
    pagination += getNoHrefLink " ... "

  [start..end].map (pageNumber)->
    pagination += getSinglePageLink pageNumber, null, route

  if end < numberOfPages
    pagination += getNoHrefLink " ... "

  pagination += nextLink
  pagination += lastLink

  return pagination

getNoHrefLink = (linkText)->
  "<a href='#'>#{linkText}  </a>"

getSinglePageLink = (pageNumber, linkText=pageNumber, route)->
  link = "<a href='#{uri.address}/#{route}?page=#{pageNumber}'>#{linkText}  </a>"
  return link

appendDecoratedTopic = (tag, queue)->
  queue.pageContent += createTagNode tag
  queue.next()

getSchemaOpeningTags = (contentType) ->
  openingTag = ""
  title = ""
  switch contentType
    when "post"
      title = "activities"
      openingTag += """<article itemscope itemtype="http://schema.org/BlogPosting">"""
    when "topic"
      title = "topics"

  openingTag +=
      """
          <div itemscope itemtype="http://schema.org/ItemList">
            <meta itemprop="mainContentOfPage" content="true"/>
            <h2 itemprop="name" class="hidden">Latest #{title}</h2>
            <meta itemprop="itemListOrder" content="Descending" />
      """

  return openingTag

getSchemaClosingTags = (contentType) ->
  closingTag = "</div>"
  closingTag += "</article>"  if contentType is "post"

  return closingTag

createTagNode = (tag)->
  tagContent = ""
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

getSidebar = ->
  """
  <aside id="main-sidebar">
    <div id="dock">
      <h3 class="sidebar-title">MY APPS</h3>
      <div id="main-nav" class="kdview kdlistview kdlistview-navigation">
        <a class="kdview kdlistitemview kdlistitemview-main-nav no-anim activity running selected" href="/Activity">
          <figure></figure>
          <cite>Activity</cite>
        </a>
        <a class="kdview kdlistitemview kdlistitemview-main-nav no-anim ide" href="/IDE">
          <figure></figure>
          <cite>IDE</cite>
        </a>
        <a class="kdview kdlistitemview kdlistitemview-main-nav no-anim teamwork" href="/Teamwork">
          <figure></figure>
          <cite>Teamwork</cite>
        </a>
        <a class="kdview kdlistitemview kdlistitemview-main-nav no-anim apps" href="/Apps">
          <figure></figure>
          <cite>Apps</cite>
        </a>
        <a class="kdview kdlistitemview kdlistitemview-main-nav no-anim devtools" href="/DevTools">
          <figure></figure>
          <cite>DevTools</cite>
        </a>
      </div>
    </div>
  </aside>
  """

getEmptyPage = ->
  putContentIntoFullPage "There is no activity yet", ""

putContentIntoFullPage = (content, pagination, graphMeta)->
  getGraphMeta  = require './graphmeta'
  analytics     = require './analytics'

  graphMeta = getGraphMeta graphMeta

  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>Koding | A New Way For Developers To Work</title>
    #{graphMeta}
  </head>
  <body itemscope itemtype="http://schema.org/WebPage" class="super activity">
    <div id="kdmaincontainer" class="kdview with-sidebar">
      #{getSidebar()}
      <section id="main-panel-wrapper" class="kdview">
        <div class="kdview kdtabpaneview activity clearfix content-area-pane active">
          <div id="content-page-activity" class="kdview content-page activity clearfix">
            <main class="kdview kdscrollview kdtabview app-content">
              #{content}
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
  putContentIntoFullPage
  getSidebar
  getEmptyPage
}
