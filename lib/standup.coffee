class Standup
  constructor: (@cron, {@at, @timezone, @args}, @callback) ->

  report: (at) ->
    return @ unless @job

    @job.stop()
    @job = @createJob(at, =>
      @job.stop()
      @start()
    )
    @

  start: ->
    @job = @createJob(@at)
    @

  createJob: (at, callback) ->
    opts =
      cronTime: @cronLine(at)
      start: true
    opts.timeZone = @timezone if @timezone
    new @cron(opts, =>
      @onTick()
      callback() if callback
    )

  cronLine: (at) ->
    [hour, minutes] = at.split ':'
    minutes = "00" if not minutes
    "00 #{minutes} #{hour} * * 1-5"

  onTick: ->
    @callback(@args) if @callback

module.exports = Standup
