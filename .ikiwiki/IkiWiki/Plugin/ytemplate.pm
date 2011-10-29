#!/usr/bin/perl
# template plugin able to use yaml data.
package IkiWiki::Plugin::ytemplate;

use warnings;
use strict;
use IkiWiki 3.00;
use YAML::Any 'Load';

our %pagesources;

sub import {
    hook(
        type => "getsetup",    #
        id   => "ytemplate",
        call => \&getsetup
    );
    hook(
        type => "preprocess",
        id   => "ytemplate",
        call => \&preprocess,
        scan => 1
    );
}

sub getsetup {
    ( plugin => { safe => 1, rebuild => undef, section => "widget" } );
}

sub preprocess {
    my ( %params ) = @_;

    if ( defined $params{yaml} ) {
        my $yaml = delete $params{yaml};
        $yaml .= "\n" if $yaml;

        my %data = %{ Load( $yaml ) };

        $params{$_} = $data{$_} for keys %data;
    }

    return IkiWiki::Plugin::template::preprocess( %params );
}

1;
