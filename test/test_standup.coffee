expect         = require 'expect.js'
sinon          = require 'sinon'

cron           = require 'cron'

hubotStandup   = require '../'
Standup        = hubotStandup.Standup
scriptStandup  = require '../lib/scripts/standup'

describe 'A standup', ->
  beforeEach ->
    @cron = sinon.mock(cron.cronJob)

    @job = stop: ->
    @jobMock = sinon.mock(@job)
    @cron.returns(@job)

  it 'can be defined at 8', ->
    new Standup(@cron, {at: '8'}).start()

    expect(@cron.calledWithNew()).to.be.ok()
    expect(@cron.calledWith(cronTime: '00 00 8 * * 1-5', start: true, onTick: sinon.match.func)).to.be.ok()

  it 'can be defined at 9:15', ->
    new Standup(@cron, {at: '9:15'}).start()

    expect(@cron.calledWith(cronTime: '00 15 9 * * 1-5', start: true, onTick: sinon.match.func)).to.be.ok()

  it 'can be defined with a timezone', ->
    new Standup(@cron, {at: '9', timezone: 'Europe/Paris'}).start()

    expect(@cron.calledWith(cronTime: '00 00 9 * * 1-5', start: true, timeZone: 'Europe/Paris', onTick: sinon.match.func)).to.be.ok()

  it 'can have a callback', (done) ->
    new Standup(@cron, {at: '9'}, () ->
      done()
    ).start()

    @cron.getCall(0).args[0].onTick()

  it 'can be stopped', ->
    standup = new Standup(@cron, {at: '9'}).start()
    @jobMock.expects('stop').once()
    standup.stop()
    @jobMock.verify()

  it 'stop only when started', ->
    standup = new Standup(@cron, {at: '9'})
    @jobMock.expects('stop').never()
    standup.stop()
    @jobMock.verify()

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

    @cron.getCall(1).args[0].onTick()

    expect(@cron.getCall(2).args[0].cronTime).to.eql('00 00 9 * * 1-5', start: true)
    @jobMock.verify()

  it 'report do nothing if not started', ->
    standup = new Standup(@cron, {at: '9'})

    @jobMock.expects('stop').never()
    standup.report '10'
    @jobMock.verify()

createResponse = (text, regexp) ->
  {Response, TextMessage} = require('hubot')
  message = new TextMessage('roger', text, 1)
  response = new Response((()->), message, message.match(regexp))
  response.send = () ->
  response

describe 'The hubot create function', ->
  beforeEach ->
    @regexp = scriptStandup.create.regexp
    @loader =
      get: ->
      create: ->
    @loaderMock = sinon.mock(@loader)

  it 'match standup with hour and users', ->
    expect('standup at 8 for user'.match(@regexp)[1]).to.eql('8')
    expect('standup at 8 for user, user2'.match(@regexp)[3]).to.eql('user, user2')

  it 'match standup with hours and minutes', ->
    expect('standup at 8:15 for user'.match(@regexp)[1]).to.eql('8:15')

  it 'match standup with timezone', ->
    expect('standup at 9 (Europe/Paris) for user'.match(@regexp)[1]).to.eql('9')
    expect('standup at 9 (Europe/Paris) for user'.match(@regexp)[2]).to.eql('Europe/Paris')

  it 'match standup with users and timezone', ->
    expect('standup at 9 (Europe/Paris) for user, user2'.match(@regexp)[3]).to.eql('user, user2')

  it 'create a standup at 8 for user', ->
    @loaderMock.expects('create').once().withArgs({at: '8', users: ['user'], user: 'roger'})

    response = createResponse('standup at 8 for user', @regexp)
    scriptStandup.create(@loader)(response)
    @loaderMock.verify()

  it 'create a standup at 9 for user2', ->
    @loaderMock.expects('create').once().withArgs({at: '9', users: ['user2'], user: 'roger'})

    response = createResponse('standup at 9 for user2', @regexp)
    scriptStandup.create(@loader)(response)

    @loaderMock.verify()

  it 'create a standup at 10 (Europe/Paris) for user1, user2', ->
    @loaderMock.expects('create').once().withArgs({at: '10', timezone: 'Europe/Paris', users: ['user1', 'user2'], user: 'roger'})

    response = createResponse('standup at 10 (Europe/Paris) for user1, user2', @regexp)
    scriptStandup.create(@loader)(response)

    @loaderMock.verify()

  it 'stop standup if previous standup defined', ->
    previousStandup = stop: ->
    previousStandupMock = sinon.mock(previousStandup)
    previousStandupMock.expects('stop').once()
    @loaderMock.expects('get').once().returns(previousStandup)

    response = createResponse('standup at 8 for user', @regexp)
    scriptStandup.create(@loader)(response)

    previousStandupMock.verify()
    @loaderMock.verify()

describe 'The hubot report function', ->
  beforeEach ->
    @regexp = scriptStandup.report.regexp

  it 'match report with hour', ->
    expect('standup report at 8'.match(@regexp)[1]).to.eql('8')

  it 'match report with hour and minutes', ->
    expect('standup report at 8:15'.match(@regexp)[1]).to.eql('8:15')

  it 'match report with 2 digit hour', ->
    expect('standup report at 15'.match(@regexp)[1]).to.eql('15')

  it 'report the standup', ->
    current =
      options:
        users: []
      report: () ->
    spy = sinon.spy(current, 'report')

    response = createResponse('standup report at 10', @regexp)

    scriptStandup.report(
      get: -> current
    )(response)
    expect(spy.withArgs('10').calledOnce).to.be.ok()

  it 'do nothing if no previous standup', ->
    response = createResponse('standup report at 10', @regexp)
    scriptStandup.report(
      get: ->
        null
    )(response)

describe 'The hubot remove function', ->
  beforeEach ->
    @regexp = scriptStandup.remove.regexp

  it 'match remove', ->
    expect('standup remove'.match(@regexp)).to.be.ok()
    expect('standup'.match(@regexp)).to.not.be.ok()

  it 'remove the standup', ->
    loader =
      destroy: ->
    spy = sinon.spy(loader, 'destroy')

    response = createResponse('standup remove', @regexp)

    scriptStandup.remove(loader)(response)
    expect(spy.calledOnce).to.be.ok()
