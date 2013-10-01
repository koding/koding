{EventEmitter} = require 'events'

jraphical = require 'jraphical'
{Base, race, dash, daisy} = require "bongo"
{CronJob} = require 'cron'
_ = require "underscore"

NAMEPERPAGE = 2
GROUPPERPAGE = 20
module.exports = class SitemapGeneratorWorker extends EventEmitter
  constructor: (@bongo, @options = {}) ->

  generateSitemapString: (urls)->
     # sitemap.XML beginning and ending parts
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" 
      xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" 
      xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">'
    sitemapFooter = '</urlset>'

    for url in urls
      sitemap += "<url><loc>#{@options.uri.address}/#{url}</loc></url>"
    sitemap += sitemapFooter

  generateSitemapName: (skip)->
    return  skip + "_" + (skip + NAMEPERPAGE)

  saveSitemap: (name, content)->
    {JSitemap} = @bongo.models
    JSitemap.update {name}, $set : {content}, {upsert : yes}, (err)-> 
      console.log err if err
  generateMainSitemap: (sitemapNames)=>
    name = "main"
    content = @generateSitemapString sitemapNames
    @saveSitemap name, content
  generate:=>
    {JName, JGroup, JSitemap} = @bongo.models

    sitemapNames = []


    groupSelector = {
      privacy:'public'
    }

    JGroup.count groupSelector, (err, groupCount)=>
      numberOfGroupPages = Math.ceil(groupCount / GROUPPERPAGE)
      for groupPageNumber in [1..numberOfGroupPages]
        groupSkip = (groupPageNumber - 1) * GROUPPERPAGE
        groupOptions = {
          limit : GROUPPERPAGE,
          skip  : groupSkip
        }
        JGroup.some groupSelector, groupOptions, (err, jGroups)=>
          publicGroups = []

          # We behave 'koding' as a public group, even though
          # its privacy is marked as "private" in the model.
          publicGroups.push 'koding'

          for group in jGroups
            publicGroups.push group.slug


          selector = {
            'slugs.group': { $in: publicGroups }
          }

          JName.count selector, (err, count)=>
            numberOfNamePages = Math.ceil(count / NAMEPERPAGE)

            queue = [1..numberOfNamePages].map (pageNumber)=>=>
                skip = (pageNumber - 1) * NAMEPERPAGE
                option = {
                  limit : NAMEPERPAGE,
                  skip  : skip
                }
                JName.some selector, option, (err, names)=>
                  urls = (name.name for name in names) 

                  sitemapName =  @generateSitemapName skip
                  content = @generateSitemapString urls
                  @saveSitemap sitemapName, content

                  sitemapNames.push sitemapName + ".xml"
                  queue.next()
            queue.push => @generateMainSitemap sitemapNames

            daisy queue


  init:->
    sitemapGeneratorCron = new CronJob @options.sitemapWorker.cronSchedule, @generate
    sitemapGeneratorCron.start()