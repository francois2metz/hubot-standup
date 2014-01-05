expect         = require 'expect.js'
sinon          = require 'sinon'

cron           = require 'cron'

hubotStandup   = require '../'
Standup        = hubotStandup.Standup

describe 'A standup', ->
  beforeEach ->
    @cron = sinon.mock(cron.cronJob)

    @job = stop: ->
    @jobMock = sinon.mock(@job)
    @cron.returns(@job)

  it 'can be defined at 8', ->
    new Standup(@cron, {at: '8'}).start()

    expect(@cron.calledWithNew()).to.be.ok()
    expect(@cron.calledWith(cronTime: '00 00 8 * * 1-5', start: true)).to.be.ok()

  it 'can be defined at 9:15', ->
    new Standup(@cron, {at: '9:15'}).start()

    expect(@cron.calledWith(cronTime: '00 15 9 * * 1-5', start: true)).to.be.ok()

  it 'can be defined with a timezone', ->
    new Standup(@cron, {at: '9', timezone: 'Europe/Paris'}).start()

    expect(@cron.calledWith(cronTime: '00 00 9 * * 1-5', start: true, timeZone: 'Europe/Paris')).to.be.ok()

  it 'can have a callback with args and callback', (done) ->
    new Standup(@cron, {at: '9', args: ['Chuck', 'Norris']}, (message) ->
      expect(message).to.eql(['Chuck', 'Norris'])
      done()
    ).start()

    @cron.getCall(0).args[1]()

  it 'can create a new cron on report', ->
    @cron.exactly(2);
    @jobMock.expects('stop').once()

    standup = new Standup(@cron, {at: '9'}).start()
    standup.report '10'

    expect(@cron.getCall(1).args[0].cronTime).to.eql('00 00 10 * * 1-5', start: true)
    @jobMock.verify()

  it 'restore the previous after report', ->
    @cron.exactly(3);
    @jobMock.expects('stop').twice()

    standup = new Standup(@cron, {at: '9'}).start()
    standup.report '10'

    @cron.getCall(1).args[1]()

    expect(@cron.getCall(2).args[0].cronTime).to.eql('00 00 9 * * 1-5', start: true)
    @jobMock.verify()

  it 'report do nothing if not started', ->
    standup = new Standup(@cron, {at: '9'})

    @jobMock.expects('stop').never()
    standup.report '10'
