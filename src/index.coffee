_ = require 'underscore'

window = {}
global.window = window

global._fixtures = []

global.fixture = (name, fixtureBody) ->
   body = fixtureBody()
   setup = body.setup ? (()->)
   teardown = body.teardown ? (()->)
   _fixtures.push {name, body,setup,teardown}

global.Runner = {}
global.Runner.run = () ->
   for fixture in global._fixtures
      console.log 'executing fixture: ' + fixture.name
      setup?()

      for own name, test of fixture.body
         continue unless name == 'setup' or name == 'teardown'
         console.log 'executing test: ' + name
         try
            test()
         catch error
            console.log error
      teardown?()

Object::shouldBeFalse = () -> throw 'expected: false, but got: ' + @ unless @ == false
Object::shouldBeTrue = () -> @ == true


fixture "sample", ->
  setup: ->
      console.log 'hello from setup'

  'the awesome failing test': ->
      console.log 'a failing test'
      true.shouldbeFalse()

  teardown: ->
      console.log 'A teardown'

Runner.run()
