# Description:
#   Remind the daily standup
#
# Commands:
#   hubot standup at 9 for user1
#   hubot standup report at 15
#   hubot standup remove

cron = require 'cron'
Standup = require '../standup'

splitUsers = (users) ->
  users.split(',').map (user) -> user.trim()

create = (loader) ->
  (msg) ->
    previous = loader.get()
    if previous
      previous.stop()
      msg.send "previous standup discarded"

    users = splitUsers(msg.match[3])
    opts =
      at: msg.match[1]
      users: users
      user: msg.message.user
    opts.timezone = msg.match[2] if msg.match[2]
    loader.create(opts)
    msg.send "standup defined at #{opts.at} for #{opts.users.join(',')}"

create.regexp = /standup at ([0-9]+:?[0-9]*) ?\(?([a-zA-Z/]+)?\)? ?for ([a-zA-Z1-9, ]+)/

report = (loader) ->
  (msg) ->
    previous = loader.get()
    return unless previous
    previous.report(msg.match[1])
    msg.send "#{previous.options.users.join(',')} standup reported at #{msg.match[1]}"

report.regexp = /standup report at ([0-9]+:?[0-9]*)/

remove = (loader) ->
  (msg) ->
    loader.destroy()
    msg.send "standup removed"

remove.regexp = /standup remove/

STANDUP = null

createLoader = (robot) ->
  get: ->
    STANDUP
  create: (opts) ->
    STANDUP = new Standup(cron.CronJob, opts, () =>
        @sendMessage opts
    ).start()
    robot.brain.data.standup = opts
  destroy: ->
    STANDUP.stop() if STANDUP
    robot.brain.data.standup = null
  sendMessage: (opts) ->
    robot.send opts.user, opts.users.join(', ') + " standup meeting!"

exports = (robot) ->
  robot.brain.on 'loaded', =>
    loader = createLoader(robot)
    if robot.brain.data.standup
      loader.create(robot.brain.data.standup)
      console.log('loaded with ', robot.brain.data.standup)

    robot.respond(create.regexp, create(loader))
    robot.respond(report.regexp, report(loader))
    robot.respond(remove.regexp, remove(loader))

exports.create = create
exports.report = report
exports.remove = remove

module.exports = exports
