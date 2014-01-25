# Hubot ping standup

A hubot script that ping the team everyday for the standup meeting.

## Install

Add **hubot-ping-standup** to your *package.json*.

    npm install --save hubot-ping-standup

Then add **hubot-standup** to *external_scripts.json*.

```javascript
[..., "hubot-ping-standup", ...]
```

## Usage

To set a standup for every week day:

    hubot standup at 8 for user, user2, user3

Specify a timezone:

    hubot standup at 8 (Europe/Paris) for user, user2, user3

Report a standup for today:

    hubot standup report at 15

Remove the standup:

    hubot standup remove

### Tests

    npm test

## License

Copyright (c) 2014 François de Metz

See [LICENSE](LICENSE).
