#!/usr/bin/perl
# template plugin able to use yaml data.
package IkiWiki::Plugin::tuttable;

use warnings;
use strict;
use IkiWiki 3.00;
use YAML::Any 'Load';

sub import {
    hook(
        type => "getsetup",    #
        id   => "tuttable",
        call => \&getsetup
    );
    hook(
        type => "preprocess",
        id   => "tuttable",
        call => \&preprocess,
        scan => 1
    );
}

sub getsetup {
    ( plugin => { safe => 1, rebuild => undef, section => "widget" } );
}

sub preprocess {
    my ( %params ) = @_;

    IkiWiki::Plugin::ytemplate::prepare_params( \%params );

    my @tutorials = @{ $params{tutorials} };
    @tutorials = reverse sort { $a->{lastupdate} <=> $b->{lastupdate} } @tutorials;
    $params{tutorials} = \@tutorials;

    return IkiWiki::Plugin::template::preprocess( %params );
}

1;
