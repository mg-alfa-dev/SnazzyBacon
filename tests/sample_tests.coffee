fixture "sample fixture 1"
  setup: ->
      console.log 'hello from setup'

  'the awesome failing test': ->
      false.should.equal(true)

  teardown: ->
      console.log 'A teardown'

fixture "sample fixture 2"
  setup: ->
      console.log 'hello from another setup'

  'the awesome passing test': ->
      t = new Boolean()
      t.should.equal(t)

