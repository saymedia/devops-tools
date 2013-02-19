# Say Media's Devops Tools

A collection of scripts and tools used at Say Media.

## statsd

### statsd-proxy-prod

Proxies to rewrite metric names to add prefixes that match our naming scheme. Also duplicates stats into a per-host statistic as well as a cluster-wide statistic. This way, an incoming counter called 'myapp.requests' gets aggregated into two different views: PROD.apps.counters.myapp.requests and PROD.hosts.gh-web.sfo-gh-web001.counters.myapp.requests.

### apache-statsd

An Apache CustomLog destination that logs interesting metrics to statsd: request rates, rates of response codes, and response size statistics.

## graphite

### sigmoid

Wrap this script in other scripts that need to report metrics or statistics to Graphite or StatsD.

### check_graphite

Compare two metrics from Graphite and create an alert if the difference is greater than the value of ``--crit`` or ``--warn``.

### carbon-proxy-*

Proxies to rewrite metrics name and do multixplexing.
