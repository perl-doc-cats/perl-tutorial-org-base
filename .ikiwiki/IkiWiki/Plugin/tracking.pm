#!/usr/bin/perl
package IkiWiki::Plugin::tracking;

use warnings;
use strict;
use IkiWiki 3.00;

sub import {
        hook(type => "getsetup", id => "tracking", call => \&getsetup);
        hook(type => "pagetemplate", id => "tracking", call => \&pagetemplate);
}

sub getsetup () {
        return
                plugin => {
                        safe => 1,
                        rebuild => 1,
                        section => "other",
                },
                piwik_id => {
                        type => "string",
                        example => "1",
                        description => "Piwik site id",
                        safe => 1,
                        rebuild => 1,
                },
		piwik_http_url => {
			type => "string",
			example => "http://www.example.com/piwik/",
			description => "Piwik base URL - http",
			safe => 1,
			rebuild => 1,
		},
		piwik_https_url => {
			type => "string",
			example => "https://ssl.example.com/piwik/",
			description => "Piwik base URL - https",
			safe => 1,
			rebuild => 1,
		},
		google_analytics_id => {
			type => "string",
			example => "UA-xxxxxx-x",
			description => "Google Analytics tracking id",
			safe => 1,
			rebuild => 1,
		}
}

my $piwikout;
my $googleout;
sub pagetemplate (@) {
	my %params=@_;
	my $page=$params{page};
	my $template=$params{template};

	if ($template->query(name => "extrafooter")) {
		my $value=$template->param("extrafooter");

		if (defined $config{piwik_id} &&
		    defined $config{piwik_http_url} &&
		    defined $config{piwik_https_url}) {
			if (! defined $piwikout) {
				my $piwiktemplate = template("piwik.tmpl", blind_cache => 1);
				my $piwik_https_url = $config{piwik_https_url};
				$piwik_https_url =~ s/\/$//;
				my $piwik_http_url = $config{piwik_http_url};
				$piwik_http_url =~ s/\/$//;

				$piwiktemplate->param(piwikhttpsbaseurl => $piwik_https_url);
				$piwiktemplate->param(piwikhttpbaseurl => $piwik_http_url);
				$piwiktemplate->param(piwikid => $config{piwik_id});
				$piwikout=$piwiktemplate->output;
			}
			$value.=$piwikout;
		}

		if (defined $config{google_analytics_id}) {
			if (! defined $googleout) {
				my $googletemplate = template("google_analytics.tmpl", blind_cache => 1);
				$googletemplate->param(googleanalyticsid => $config{google_analytics_id});
				$googleout=$googletemplate->output;
			}
			$value.=$googleout;
		}

		$template->param(extrafooter => $value);
	}
}

1
