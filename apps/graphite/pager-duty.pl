#!/usr/bin/env perl

use 5.010;

use strict;
use warnings;

use Getopt::Long;

use HTTP::Request;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use JSON;
use DateTime::Format::ISO8601;

GetOptions(
    'api-key=s' => \(my $api_key),
    'api-url=s' => \(my $api_url='https://saymedia.pagerduty.com/api/v1/incidents'),
    'from=s'    => \(my $from=undef),
    'until=s'   => \(my $until=undef),
    'event=s'   => \(my $event_name='apps.events.pagerduty.incidents'),
    'help'      => \(my $usage),
    'debug'     => \(my $debug=0),
);

usage() if ($usage);

if (!$api_key) {
    die "--api-key is missing\n";
    usage();
}

if (!defined $from || !defined $until) {
    my $dt = DateTime->now();
    my $yesterday = $dt->clone->subtract(days => 1);
    $from  = DateTime::Format::ISO8601->parse_datetime($yesterday) unless defined $from;
    $until = DateTime::Format::ISO8601->parse_datetime($dt)        unless defined $until;
}

my $uri = URI->new($api_url);
$uri->query_form_hash({since => $from, until => $until});

my $ua  = LWP::UserAgent->new();

fetch_incidents($uri, 0);

sub fetch_incidents {
    my ($uri, $done) = @_;

    my $json = api_call($uri, 1);

    foreach my $incident (@{$json->{incidents}}) {
        get_and_send_metric($incident);
        $done++;
    }

    if ($done < $json->{total}){
        $uri->query_form_hash({offset => $done, since => $from, until => $until});
        fetch_incidents($uri, $done);
    }
}

sub get_and_send_metric {
    my $incident = shift;

    my $t    = DateTime::Format::ISO8601->parse_datetime( $incident->{created_on} );
    my $url  = $api_url.'/'.$incident->{id};
    my $json = api_call($url, 0);
    my $service = $json->{service}->{name};
    my $status  = $json->{status};
    my $event = "$event_name.$service.$status";
    say "$event ".$t->epoch() if $debug;
    exec('sigmoid', '--event', '--env=PROD', $event, $t->epoch());
}

sub usage {
    say "usage: $0 <options>";
    say " - api-key : pager duty's API key";
    say " - api-url : pager duty's API url";
    say " - from";
    say " - until";
    say " - event : prefix for the event";
    say " - help : display this message";
    exit 1;
}

sub api_call {
    my ($uri, $fatal) = @_;

    my $req = HTTP::Request->new('GET', $uri);
    $req->header('Authorization', 'Token token='.$api_key);
    $req->header('Content-type', 'application/json');

    my $res  = $ua->request($req);

    if ($fatal && !$res->is_success) {
        say "Failed to contact pager duty's API: " . $res->content;
        die ;
    }

    my $json;
    eval {$json = decode_json($res->content);};

    if ($@) {
        say $uri;
        say $res->content;
    }
    return $json;
}
