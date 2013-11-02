{EventEmitter} = require 'events'

jraphical = require 'jraphical'
{Base, race, dash, daisy} = require "bongo"
{CronJob} = require 'cron'

NAMEPERPAGE = 50000
GROUPPERPAGE = 5

module.exports = class SitemapGeneratorWorker extends EventEmitter
  constructor: (@bongo, @options = {}) ->

  generateSitemapString: (urls, isMain=false)->

    # sitemap.XML beginning and ending parts
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" 
      xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" 
      xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">'
    sitemapFooter = '</urlset>'

    # while generating main sitemap, we don't need hashbang in the url.
    for url in urls
      if isMain
        sitemap += "<url><loc>#{@options.uri.address}/#{url}</loc></url>"
      else
        sitemap += "<url><loc>#{@options.uri.address}/#!/#{url}</loc></url>"
    sitemap += sitemapFooter

  generateSitemapName: (groupPageNumber, skip)->
    return  "sitemap_" + groupPageNumber + "_" + skip + "_" + (skip + NAMEPERPAGE) + ".xml"

  saveSitemap: (name, content)->
    {JSitemap} = @bongo.models
    JSitemap.update {name}, $set : {content}, {upsert : yes}, (err)-> 
      console.log err if err

  generate:=>
    {JName, JGroup, JSitemap} = @bongo.models

    groupSelector = {
      privacy:'public'
    }

    generateMainSitemap = (sitemapNames)=> 
      name = "sitemap.xml"
      content = @generateSitemapString sitemapNames, true
      @saveSitemap name, content

    JGroup.count groupSelector, (err, groupCount)=>
      numberOfGroupPages = Math.ceil(groupCount / GROUPPERPAGE)

      publicGroups = []

      # We behave 'koding' as a public group, even though
      # its privacy is marked as "private" in the model.
      # We add 'koding' group to publicGroups selector for the first cycle.
      publicGroups.push 'koding'

      groupQueue = [1..numberOfGroupPages].map (groupPageNumber)=>=>
        groupSkip = (groupPageNumber - 1) * GROUPPERPAGE
        groupOptions = {
          limit : GROUPPERPAGE,
          skip  : groupSkip
        }
        JGroup.some groupSelector, groupOptions, (err, jGroups)=>

          for group in jGroups
            publicGroups.push group.slug

          selector = {
            'slugs.group': { $in: publicGroups }
          }

          # Empty the group, it'll be filled in next cycle.
          publicGroups = []

          JName.count selector, (err, count)=>
            numberOfNamePages = Math.ceil(count / NAMEPERPAGE)
            queue = [1..numberOfNamePages].map (pageNumber)=>=>
              skip = (pageNumber - 1) * NAMEPERPAGE
              option = {
                limit : NAMEPERPAGE,
                skip  : skip
              }
              JName.some selector, option, (err, names)=>
                if names
                  urls = (name.name for name in names) 
                  sitemapName =  @generateSitemapName groupPageNumber, skip
                  content = @generateSitemapString urls
                  @saveSitemap sitemapName, content

                  groupQueue.sitemapNames or= []
                  groupQueue.sitemapNames.push sitemapName
                queue.next()
            queue.push => groupQueue.next()
            daisy queue
            

      groupQueue.push => generateMainSitemap(groupQueue.sitemapNames)
      daisy groupQueue


  init:->
    sitemapGeneratorCron = new CronJob @options.sitemapWorker.cronSchedule, @generate
    sitemapGeneratorCron.start()
