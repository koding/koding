{argv}                               = require 'optimist'
{uri}                                = require('koding-config-manager').load("main.#{argv.c}")
{ daisy }                            = require "bongo"
{ Relationship }                     = require 'jraphical'
{ createActivityContent, decorateComment } = require '../helpers'

ITEMSPERPAGE = 20

module.exports = (bongo, page, contentType, callback)=>
  {JName, JAccount, JStatusUpdate, JTag} = bongo.models
  skip = 0
  if page > 0
    skip = (page - 1) * ITEMSPERPAGE


  options = {
    limit : ITEMSPERPAGE
    skip  : skip
    sort: 'meta.createdAt': -1
  }

  if contentType is "Activity"
    model = JStatusUpdate
  else if contentType is "Topics"
    model = JTag
  else
    return callback new Error "Unknown content type.", null

  pageContent = ""
  model.count {}, (error, count)=>
    return callback error, null  if error
    return callback null, null  if count is 0
    model.some {}, options, (err, contents)=>
      return callback err, null  if err
      return callback null, null  if contents.length is 0
      queue = [0..contents.length - 1].map (index)=>=>
        queue.pageContent or= ""

        content = contents[index]

        if contentType is "Activity"
          createFullHTML = no
          putBody = no
          createActivityContent JAccount, content, {}, createFullHTML, putBody, (error, content)=>
            queue.next()  if error or not content
            queue.pageContent = queue.pageContent + content
            queue.next()
        else if contentType is "Topics"
          appendDecoratedTopic content, queue
        else queue.next()
      queue.push =>
        schemaorgTagsOpening = getSchemaOpeningTags contentType
        schemaorgTagsClosing = getSchemaClosingTags contentType

        content = schemaorgTagsOpening + queue.pageContent + schemaorgTagsClosing

        pagination = getPagination page, count, contentType
        fullPage = putContentIntoFullPage content, pagination
        return callback null, fullPage
      daisy queue

getPagination = (currentPage, numberOfItems, contentType)->
  # This is the number of adjacent link around current page.
  # E.g. let current page be 9, then pagination will look like this:
  # First Prev ... 4 5 6 7 8 9 10 11 12 13 14 ... Next Last
  # (Except 3-dots, they are useless for bots.)
  PAGERWINDOW = 5

  numberOfPages = Math.ceil(numberOfItems / ITEMSPERPAGE)
  firstLink = prevLink = nextLink = lastLink = ""

  if currentPage > 1
    firstLink = getSinglePageLink 1, contentType, "First"
    prevLink  = getSinglePageLink (currentPage - 1), contentType, "Previous"

  if currentPage < numberOfPages
    lastLink  = getSinglePageLink numberOfPages, contentType, "Last"
    nextLink  = getSinglePageLink (currentPage + 1), contentType, "Next"

  pagination = firstLink + prevLink

  start = 1
  end = numberOfPages

  start = currentPage - PAGERWINDOW  if currentPage > PAGERWINDOW

  if currentPage + PAGERWINDOW < numberOfPages
    end   = currentPage + PAGERWINDOW

  [start..end].map (pageNumber)=>
    pagination += getSinglePageLink pageNumber, contentType

  pagination += nextLink
  pagination += lastLink

  return pagination


getSinglePageLink = (pageNumber, contentType, linkText=pageNumber)->
  # link = "<a href='#{uri.address}/#!/Activity/&page=#{pageNumber}'>#{linkText}  </a>"
  link = "<a href='#{uri.address}/#!/#{contentType}?page=#{pageNumber}'>#{linkText}  </a>"
  return link

appendDecoratedTopic = (tag, queue)=>
  queue.pageContent += createTagNode tag
  queue.next()

getSchemaOpeningTags = (contentType)=>
  openingTags = ""
  if contentType is "Activity"
    openingTags =
      """
        <article itemscope itemtype="http://schema.org/BlogPosting">
          <div itemscope itemtype="http://schema.org/ItemList">
            <meta itemprop="mainContentOfPage" content="true"/>
            <h2 itemprop="name">Latest activities</h2><br>
            <meta itemprop="itemListOrder" content="Descending" />
      """
  else if contentType is "Topics"
    openingTags =
      """
        <div itemscope itemtype="http://schema.org/ItemList">
          <meta itemprop="mainContentOfPage" content="true"/>
          <h2 itemprop="name">Latest topics</h2><br>
          <meta itemprop="itemListOrder" content="Descending" />
      """
  return openingTags

getSchemaClosingTags = (contentType)=>
  closingTags = ""
  if contentType is "Activity"
    closingTags = "</div></article>"
  else if contentType is "Topics"
    closingTags = "</div>"
  return closingTags

createTagNode = (tag)->
  tagContent = ""
  if tag.title
    tagContent +=
    """
      <p>
        <a href="#{uri.address}/#!/Topics/#{tag.slug}"><span itemprop="itemListElement">#{tag.title}</span></a>
      </p>
    """
  if tag?.counts?.followers?
    tagContent += createFollowersCount tag.counts.followers
    tagContent += createUserInteractionMeta tag.counts.followers
  return tagContent

createFollowersCount = (numberOfFollowers)->
  return "<span>#{numberOfFollowers}</span> followers"

createUserInteractionMeta = (numberOfFollowers)->
  userInteractionMeta = "<meta itemprop=\"interactionCount\" content=\"UserComments:#{numberOfFollowers}\"/>"
  return userInteractionMeta

putContentIntoFullPage = (content, pagination)->
  getGraphMeta  = require './graphmeta'
  fullPage =
    """
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <title>Koding</title>
        #{getGraphMeta()}
      </head>
        <body itemscope itemtype="http://schema.org/WebPage">
          <a href="#{uri.address}">Koding</a><br />
          #{content}
          #{pagination}
        </body>
      </html>
    """
  return fullPage