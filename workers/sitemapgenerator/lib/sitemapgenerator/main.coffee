{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

SitemapGeneratorWorker = require './sitemapgeneratorworker'

{uri, sitemapWorker} = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Sitemap Generator Worker #{process.pid}"
  stats_id: "worker.sitemapgenerator." + process.pid
  interval : 30000

sitemapWorker = new SitemapGeneratorWorker koding, {sitemapWorker, uri}
sitemapWorker.init()