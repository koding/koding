{ serveHome } = require './../helpers'
Crawler       = require './../../crawler'

module.exports = (req, res, next)->
  if req.query._escaped_fragment_?
    staticHome = require "../crawler/staticpages/kodinghome"
    slug       = req.query._escaped_fragment_
    return res.status(200).send staticHome() if slug is ""
    return Crawler.crawl koding, {req, res, slug}
  else
    serveHome req, res, next