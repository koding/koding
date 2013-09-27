{EventEmitter} = require 'events'

jraphical = require 'jraphical'
{Base, race, dash} = require "bongo"
{CronJob} = require 'cron'
_ = require "underscore"

NPERPAGE = 2
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
    return  skip + "_" + (skip + NPERPAGE)

  saveSitemap: (name, content)->
    {JSitemap} = @bongo.models
    JSitemap.update {name}, $set : {content}, {upsert : yes}, (err)-> 
      console.log err if err

  generate:=>
    {JName, JGroup, JSitemap} = @bongo.models

    sitemapNames = []
    JGroup.all { privacy:'public'}, (err, jGroups)=>
      publicGroups = []

      # We behave koding is a public group, even though
      # its privacy is marked as "private" in the model.
      publicGroups.push 'koding'

      for group in jGroups
        publicGroups.push group.slug

      selector = {
        'slugs.group': { $in: publicGroups }
      }

      JName.count selector, (err, count)=>
        numberOfPages = Math.ceil(count / NPERPAGE)

        queue = [1..numberOfPages].map (pageNumber)=>=>
          skip = (pageNumber - 1) * NPERPAGE
          option = {
            limit : NPERPAGE,
            skip  : skip
          }
          JName.some selector, option, (err, names)=>

            urls = (name.name for name in names) 

            sitemapName =  @generateSitemapName skip
            content = @generateSitemapString urls
            @saveSitemap sitemapName, content

            sitemapNames.push sitemapName + ".xml"
            queue.fin()

        dash queue, (err)=>
          console.log err if err
          # This is root node of all sitemaps, its name is "main"
          name = "main"
          content = @generateSitemapString sitemapNames
          @saveSitemap name, content

  init:->
    sitemapGeneratorCron = new CronJob @options.sitemapWorker.cronSchedule, @generate
    sitemapGeneratorCron.start()