mr = require 'Mr.Async'
_ = require 'underscore'
webdriver = require 'selenium-webdriver'
Comparison = require './comparison'

class Viff
  constructor: (seleniumHost) ->
    @builder = new webdriver.Builder().usingServer(seleniumHost)

  takeScreenshot: (browserName, envHost, url, callback) -> 
    defer = mr.Deferred()
    defer.done(callback)
    
    @builder = @builder.withCapabilities { browserName: browserName }
    driver = @builder.build()

    envName = _.first(envName for envName of envHost)
    driver.get envHost[envName] + url

    driver.takeScreenshot().then (base64Img) ->
      driver.close()
      defer.resolve base64Img

    defer.promise()

  takeScreenshots: (browsers, envHosts, links, callback) ->
    defer = mr.Deferred()
    defer.done callback

    compares = {}
    returned = 0
    total = browsers.length * links.length
    that = this

    _.each browsers, (browser) ->
      compares[browser] = compares[browser] || {}
      
      _.each links, (url) ->
        envCompares = {}

        _.each envHosts, (host, env) ->
          envHost = {}
          envHost[env] = host
          
          that.takeScreenshot browser, envHost, url, (base64Img) ->
            envHost[env] = base64Img
            _.extend(envCompares, envHost)

            if _.isEqual _.keys(envCompares), _.keys(envHosts)
              compares[browser][url] = new Comparison(envCompares)
              returned++

            if returned == total
              defer.resolve compares
          
    defer.promise()

  @diff: (compares, callback) ->
    defer = mr.Deferred()
    defer.done callback

    comparisons = Viff.comparisons(compares)
    returned = 0
    _.each comparisons, (comparison) ->
      comparison.diff (diffImgBase64) ->
        defer.resolve(compares) if returned++ == comparisons.length - 1

    defer.promise()

  @comparisons: (compares) ->
    ret = []
    _.each compares, (urls, browserName) -> 
      _.each urls, (comparison, url) ->
        ret.push comparison

    ret

module.exports = Viff