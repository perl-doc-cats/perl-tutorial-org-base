#!/usr/bin/perl
package IkiWiki::Plugin::easehtmlscrubber;

use warnings;
use strict;
use IkiWiki 3.00;


sub import {
    hook( type => "sanitize", id => "easehtmlscrubber", call => \&easehtmlscrubber, first => 1 );
}

sub getsetup () {
    return (
        plugin => {
            description => "allow some twitter attribs to pass through the scrubber",
            safe        => 1,
            rebuild     => undef,
        },
    );
}

sub easehtmlscrubber {
    my %params=@_;
    
    my $scrubber = IkiWiki::Plugin::htmlscrubber::scrubber();

    $scrubber->{_rules}{_}{$_} = 1 for qw( data-url data-text data-count );

    return $params{content};
}

1;
