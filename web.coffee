express = require 'express'
Feed = require 'feed'
moment = require 'moment'
_ = require 'lodash'

loremIpsum = require 'lorem-ipsum'
seedRandom = require 'seed-random'

app = express()

app.use express.logger()

units = {
    second: {
        nextUp: 'minute',
        mustDivide: 60
    }
    minute: {
        nextUp: 'hour'
        mustDivide: 60
    }
    hour: {
        nextUp: 'day'
        mustDivide: 24
    }
    day: {
        nextUp: 'year'
        mustDivide: 1
    }
    month: {
        nextUp: 'year'
        mustDivide: 12
    }
    year: {
        mustDivide: 1
    }
}

getNearest = (interval, unit) ->
    if interval == 1
        return moment().utc().startOf(unit)
    else
        unitOptions = units[unit]
        if unitOptions.mustDivide % interval != 0
            throw "When using #{unit}s the interval must divide #{unitOptions.mustDivide}"

        now = moment().utc()
        returnDate = now.clone().startOf(unitOptions.nextUp || unit)

        returnDate[unit](now[unit]() - now[unit]() % interval)

        return returnDate

app.get '/', (request, response) ->
    response.send """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>Lorem RSS</title>
        <meta name="description" content="Web service that generates lorem ipsum RSS feeds">

        <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/foundation/4.2.3/css/normalize.min.css">
        <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/foundation/4.2.3/css/foundation.min.css">

        <style type="text/css">
            ul.indent {
                position: relative;
                left: 20px;
            }
        </style>
    </head>
    <body>
        <div class="row">
            <div class="large-12 columns">
                <h1>Lorem RSS</h1>
                <p>
                    Generates RSS feeds with content updated at regular intervals. I wrote this to
                    answer a <a href="http://stackoverflow.com/questions/18202048/are-there-any-constantly-updating-rss-feed-services-to-use-for-testing-or-just">question I asked on Stack Overflow</a>.
                </p>
                <h2>API</h2>
                <p>
                    Visit <a href="/feed">/feed</a>, with the following optional parameters:
                </p>        
                <ul class="disc indent">
                    <li>
                        <em>unit</em>: one of second, minute, day, month, or year
                    </li>
                    <li>
                        <em>interval</em>: an integer to repeat the units at.
                        For seconds and minutes this interval must evenly divide 60,
                        for month it must evenly divide 12, and for day and year it
                        can only be 1.
                    </li>
                </ul>
                <h2>Examples</h2>
                <ul class="disc indent">
                    <li>
                        The default, updates once a minute: <a href="/feed">/feed</a>
                    </li>
                    <li>
                        Update every second instead of minute: <a href="/feed?unit=minute">/feed?unit=minute</a>
                    </li>
                    <li>
                        Update every 30 seconds: <a href="/feed?unit=second&interval=30">/feed?unit=second&interval=30</a>
                    </li>
                    <li>
                        Update once a day: <a href="/feed?unit=day">/feed?unit=day</a>
                    </li>
                    <li>
                        Update every 6 months: <a href="/feed?unit=month&interval=6">/feed?unit=month&interval=6</a>
                    </li>
                    <li>
                        Update once a year: <a href="/feed?unit=year">/feed?unit=year</a>
                    </li>
                    <li>
                        <strong>Invalid example:</strong>
                        update every 7 minutes (does not evenly divide 60):
                        <a href="/feed?unit=minute&interval=7">/feed?unit=minute&interval=7</a>
                    </li>
                </ul>
                <hr/>
                <p class="copyright">
                    <a rel="license" href="http://creativecommons.org/licenses/by/3.0/deed.en_US"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by/3.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" href="http://purl.org/dc/dcmitype/Text" property="dct:title" rel="dct:type">Lorem RSS</span> (this page and the feeds generated) by <span xmlns:cc="http://creativecommons.org/ns#" property="cc:attributionName">Michael Bertolacci</span> are licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/deed.en_US">Creative Commons Attribution 3.0 Unported License</a>.
                </p>
            </div>
        </div>
    </body>
</html>
    """


app.get '/feed', (request, response) ->
    if request.query.interval?
        interval = parseInt request.query.interval
    else
        interval = 1

    if not interval
        response.send(500, "Interval must be an integer")
        return
    if interval <= 0
        response.send(500, "Interval must be greater than 0")
        return

    unit = request.query.unit || 'minute'

    if not units[unit]
        response.send(500, "Unit must be one of #{_.keys(units).join(', ')}")
        return

    feed = new Feed({
        title: "Lorem ipsum feed for an interval of #{interval} #{unit}s",
        description: 'This is a constantly updating lorem ipsum feed'
        link: 'http://example.com/',
        image: 'http://example.com/image.png',
        copyright: 'Michael Bertolacci, licensed under a Creative Commons Attribution 3.0 Unported License.',

        author: {
            name: 'Michael Bertolacci',
            email: '',
            link: 'https://mgnbsoftware.com'
        }
    })

    pubDate = getNearest(interval, unit)

    for i in [0...10]
        feed.item {
            title: "Lorem ipsum #{pubDate.format()}",
            description: loremIpsum(
                random: () ->
                    seedRandom(pubDate.unix())()
            )
            link: "http://example.com/test/#{pubDate.format('X')}"
            date: pubDate.clone().toDate()
        }
        pubDate = pubDate.subtract(interval, unit)

    response.set 'Content-Type', 'application/rss+xml'
    response.send feed.render('rss-2.0');


port = process.env.PORT || 5000;

app.listen port, () ->
  console.log("Listening on " + port);
