require 'should'
_ = require 'underscore'
glob = require 'glob'
path = require 'path'
#jsdom = require 'jsdom'

global.window = global
global.document = {}# = jsdom.jsdom()
global.navigator = {}

navigator.userAgent = ""
document.addEventListener = ->

global._fixtures = []

global.fixture = (name, fixtureBody) ->
   body = fixtureBody
   setup = body.setup ? (()->)
   teardown = body.teardown ? (()->)
   _fixtures.push {name, body,setup,teardown}

class global.Runner
  constructor: (@testRoot, @fileMatcher) ->
    @files = glob.sync "#{@testRoot}/**/#{fileMatcher}"

global.Runner.run = () ->
  @tests = 0
  @errors = []
  @passingTests = []
  @failingTests = []
  @testNameFormatter = (fixture, test) -> "#{fixture} \n\t #{test}"
  for fixture in global._fixtures
      console.log 'executing fixture: ' + fixture.name
       
      for own testName, testAction of fixture.body
        continue if testName == 'setup' or testName == 'teardown'
        
        @tests++
        try
          fixture.setup?()
        catch error
          console.log "error in setup for : #{testName} \n\t Error: #{error}"
          
        try
          testAction()
          @passingTests.push testName
        catch error
          @errors.push  "error in test #{fixture.name} -> #{testName} \n\t Error: #{error} \n\t Trace: #{error.stack}"
          @failingTests.push @testNameFormatter(fixture.name, testName)

        try
          fixture.teardown?()
        catch error
          console.log "error in teardown for: #{testName} \n\t Error: #{error}"

    console.log "ran #{@tests} tests >> #{@passingTests.length} passed >> #{@failingTests.length} failed"
    if @failingTests.length > 0 then _.map @failingTests, (o) -> console.log "#{o}\n"
    if @errors.length > 0 then _.map @errors, (o) -> console.log "#{o}\n"



fixture "sample"
  setup: ->
      console.log 'hello from setup'

  'the awesome failing test': ->
      t = new Boolean()
      t.should.equal(t)
      false.should.equal(true)

  teardown: ->
      console.log 'A teardown'

Runner.run()
