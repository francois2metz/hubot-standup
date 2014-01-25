class Standup
  constructor: (@cron, @options, @callback) ->
    {@at, @timezone} = @options

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

  stop: ->
    @job.stop() if @job
    @

  createJob: (at, callback) ->
    opts =
      cronTime: @cronLine(at)
      start: true
      onTick: =>
        @onTick()
        callback() if callback
    opts.timeZone = @timezone if @timezone
    new @cron(opts)

  cronLine: (at) ->
    [hour, minutes] = at.split ':'
    minutes = "00" if not minutes
    "00 #{minutes} #{hour} * * 1-5"

  onTick: ->
    @callback() if @callback

module.exports = Standup
