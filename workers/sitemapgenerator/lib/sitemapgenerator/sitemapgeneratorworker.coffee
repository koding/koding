{EventEmitter} = require 'events'

jraphical = require 'jraphical'
{Base, race, dash, daisy} = require "bongo"
{CronJob} = require 'cron'

NAMEPERPAGE = 50000

module.exports = class SitemapGeneratorWorker extends EventEmitter
  constructor: (@bongo, @options = {}) ->

  generateSitemapString: (urls)->
    # sub-sitemaps beginning and ending parts
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
      xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
      xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">'
    sitemapFooter = '</urlset>'

    for url in urls
      if not /^guest-/.test url
        # this URL SHOULD have hashbang, DON'T remove it.
        sitemap += "<url><loc>#{@options.uri.address}/#!/#{url}</loc></url>"
    sitemap += sitemapFooter
    return sitemap

  generateSitemapIndexString: (sitemapNames)->
    # sitemap.xml (sitemap index) beginning and ending parts
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    sitemapFooter = '</sitemapindex>'

    for sitemapURL in sitemapNames
      sitemap += "<sitemap><loc>#{@options.uri.address}/#{sitemapURL}</loc></sitemap>"
    sitemap += sitemapFooter
    return sitemap

  generateSitemapName: (skip)->
    return  "sitemap_koding_" + skip + "_" + (skip + NAMEPERPAGE) + ".xml"

  saveSitemap: (name, content)->
    {JSitemap} = @bongo.models
    JSitemap.update {name}, $set : {content}, {upsert : yes}, (err)->
      return console.log err if err

  saveSitemapIndex: (sitemapNames)=>
    name = "sitemap.xml"
    content = @generateSitemapIndexString sitemapNames
    @saveSitemap name, content
    console.timeEnd 'Sitemap generator worker'

  generate:=>
    console.time 'Sitemap generator worker'
    console.log 'Sitemap generation started.'
    {JName, JSitemap} = @bongo.models

    feedLinksAdded = no
    activityFeedURL = "Activity"
    topicsFeedURL = "Topics"

    selector = {
      $or: [
        {
          'slugs.group': 'koding',
          'slugs.constructorName': 'JNewStatusUpdate'
        }
        {
          'slugs.usedAsPath':'username'
          'slugs.slug':{ $not: /guest-*/ } # We don't want to count guests.
        }
      ]
    }

    JName.count selector, (err, count)=>
      console.log err  if err
      console.log "There are ", count, " items to be added to sitemaps."
      numberOfNamePages = Math.ceil(count / NAMEPERPAGE)

      queue = [1..numberOfNamePages].map (pageNumber)=>=>
        queue.sitemapNames or= []
        skip = (pageNumber - 1) * NAMEPERPAGE
        option = {
          limit : NAMEPERPAGE,
          skip  : skip
        }
        JName.some selector, option, (err, names)=>
          if names
            urls = (name.name for name in names)

            unless feedLinksAdded
              urls.push activityFeedURL
              urls.push topicsFeedURL
              feedLinksAdded = yes

            sitemapName =  @generateSitemapName skip
            content = @generateSitemapString urls
            @saveSitemap sitemapName, content

            queue.sitemapNames.push sitemapName
          queue.next()
      queue.push => @saveSitemapIndex(queue.sitemapNames)
      daisy queue


  init:->
    sitemapGeneratorCron = new CronJob @options.sitemapWorker.cronSchedule, @generate
    sitemapGeneratorCron.start()
