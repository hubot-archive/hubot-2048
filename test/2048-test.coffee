chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe '2048', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()

    require('../src/2048')(@robot)

  it 'registers respond listeners', ->
    expect(@robot.respond).to.have.been.calledWith(/2048 me/i)
    expect(@robot.respond).to.have.been.calledWith(/2048 help/i)
    expect(@robot.respond).to.have.been.calledWith(/2048 (u(p)?|d(own)?|l(eft)?|r(ight)?)/i)
    expect(@robot.respond).to.have.been.calledWith(/2048 reset/i)
    expect(@robot.respond).to.have.been.calledWith(/2048 stop/i)