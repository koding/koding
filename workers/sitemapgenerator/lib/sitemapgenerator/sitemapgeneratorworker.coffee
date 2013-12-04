{EventEmitter} = require 'events'

jraphical = require 'jraphical'
{Base, race, dash, daisy} = require "bongo"
{CronJob} = require 'cron'

NAMEPERPAGE = 50000
GROUPPERPAGE = 5

module.exports = class SitemapGeneratorWorker extends EventEmitter
  constructor: (@bongo, @options = {}) ->

  generateSitemapString: (urls)->
    # sitemap.xml beginning and ending parts
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
      xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
      xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">'
    sitemapFooter = '</urlset>'

    # while generating main sitemap, we don't need hashbang in the url.
    for url in urls
      sitemap += "<url><loc>#{@options.uri.address}/#!/#{url}</loc></url>"
    sitemap += sitemapFooter
    return sitemap

  generateSitemapIndexString: (sitemapNames)->
    # sitemapindex.xml beginning and ending parts
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    sitemapFooter = '</sitemapindex>'

    # while generating main sitemap, we don't need hashbang in the url.
    for sitemapURL in sitemapNames
      sitemap += "<sitemap><loc>#{@options.uri.address}/#{sitemapURL}</loc></sitemap>"
    sitemap += sitemapFooter
    return sitemap

  generateSitemapName: (skip)->
    return  "sitemap_koding_" + skip + "_" + (skip + NAMEPERPAGE) + ".xml"

  saveSitemap: (name, content)->
    {JSitemap} = @bongo.models
    JSitemap.update {name}, $set : {content}, {upsert : yes}, (err)->
      console.log err if err

  generate:=>
    {JName, JGroup, JSitemap} = @bongo.models

    groupSelector = {
      privacy:'public'
    }
    generateSitemapIndex = (sitemapNames)=>
      name = "sitemap.xml"
      content = @generateSitemapIndexString sitemapNames
      @saveSitemap name, content

    selector = {
      $or: [
        { 'slugs.group': 'koding' },
        { 'slugs.usedAsPath':'username' }
      ]
    }

    JName.count selector, (err, count)=>
      numberOfNamePages = Math.ceil(count / NAMEPERPAGE)

      queue = [1..numberOfNamePages].map (pageNumber)=>=>
        queue.sitemapNames = []
        skip = (pageNumber - 1) * NAMEPERPAGE
        option = {
          limit : NAMEPERPAGE,
          skip  : skip
        }
        JName.some selector, option, (err, names)=>
          if names
            urls = (name.name for name in names)
            sitemapName =  @generateSitemapName skip
            content = @generateSitemapString urls
            @saveSitemap sitemapName, content

            queue.sitemapNames or= []
            queue.sitemapNames.push sitemapName
          queue.next()
      queue.push => generateSitemapIndex(queue.sitemapNames)
      daisy queue


  init:->
    sitemapGeneratorCron = new CronJob @options.sitemapWorker.cronSchedule, @generate
    sitemapGeneratorCron.start()
