#!/usr/bin/perl

# Idea based on the flattr plugin
# Copyright © 2006-2011 Joey Hess <joey@ikiwiki.info>
# Copyright © 2011 Bernd Zeimetz <bernd@bzed.de>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package IkiWiki::Plugin::plusone;

use warnings;
use strict;
use IkiWiki 3.00;

sub import {
    hook( type => "getsetup",   id => "plusone", call => \&getsetup );
    hook( type => "preprocess", id => "plusone", call => \&preprocess );
    hook( type => "format",     id => "plusone", call => \&format );
    hook( type => "sanitize",   id => "plusone", call => \&sanitize, last => 1 );
}

sub getsetup () {
    return plugin => {
        description => "Plugin to render +1 buttons",
        safe        => 1,
        rebuild     => undef,
      },
      plusone_count => {
        type        => "boolean",
        description => "Indicates whether or not to render an aggregate count",
        link        => "http://code.google.com/apis/+1button/#script-parameters",
        safe        => 1,
        rebuild     => undef
      },
      plusone_size => {
        type        => "string",
        example     => 'standard',
        description => 'The button size to load {small, medium, standard, tall}',
        advanced    => 1,
        safe        => 1,
        rebuild     => undef,
        link        => 'http://code.google.com/apis/+1button/#plusonetag-parameters'
      },
      plusone_lang => {
        type        => "string",
        example     => 'en-US',
        description => 'The value must be one of the valid language values for the +1 button.',
        advanced    => 1,
        safe        => 1,
        rebuild     => undef,
        link        => 'http://code.google.com/apis/+1button/#languages'
      },
      ;
}

my %plus1_pages;
my %plus1_buttons;

sub preprocess (@) {
    eval q{use Digest::MD5 'md5_hex'};
    error( $@ ) if $@;

    my %params = @_;

    $plus1_pages{ $params{destpage} } = 1;

    my $url = $params{url};
    if ( !defined $url ) {
        $url = urlto( $params{page}, "", 1 );
    }

    my $button;
    if ( $config{html5} ) {
        $button =
            '<div class="g-plusone" data-size="'
          . ( ( defined $config{plusone_size} ) ? $config{plusone_size} : 'standard' )
          . '" data-count="'
          . ( ( ( defined $config{plusone_count} ) && $config{plusone_count} ) ? 'true' : 'false' )
          . '" data-href="'
          . $url
          . '"></div>';
    }
    else {
        $button =
            '<g:plusone size="'
          . ( ( defined $config{plusone_size} ) ? $config{plusone_size} : 'standard' )
          . '" count="'
          . ( ( ( defined $config{plusone_count} ) && $config{plusone_count} ) ? 'true' : 'false' )
          . '" href="'
          . $url
          . '"></g:plusone>';
    }
    my $button_md5 = md5_hex( $button );
    $plus1_buttons{$button_md5} = $button;
    return 'PLUSBUTTONTOKEN_' . $button_md5 . ' ';
}

sub format (@) {
    my %params = @_;

    # Add +1 button's javascript to pages with +1 buttons.
    if ( $plus1_pages{ $params{page} } ) {
        if ( !( $params{content} =~ s!^(<body[^>]*>)!$1.plus1js()!em ) ) {

            # no <body> tag, probably in preview mode
            $params{content} = plus1js() . $params{content};
        }
    }
    return $params{content};
}

sub sanitize (@) {
    my %params = @_;

    # replace button tokens after htmlscrubber.
    # Needs to be don in the sanitize hook so the changes end up in the rss/atom
    # feeds, too.
    $params{content} =~ s!PLUSBUTTONTOKEN_([^ ]+) !plus1button($1)!eg;
    return $params{content};
}

sub plus1button(@) {
    my $md5 = shift;

    if ( $plus1_buttons{$md5} ) {
        return $plus1_buttons{$md5};
    }
    else {
        return ( '&#x5b;Failed to expand PLUSBUTTONTOKEN_' . $md5 . '&#x5d;' );
    }
}

my $plus1js_cached;

sub plus1js {
    return $plus1js_cached if defined $plus1js_cached;

    my $lang = "";
    $lang = "window.___gcfg = {lang: '$config{plusone_lang}'};" if defined $config{plusone_lang};

    my $js = qq{<script type="text/javascript">
  $lang

  (function() {
    var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
    po.src = 'https://apis.google.com/js/plusone.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
  })();
</script>
<script type="text/javascript" src="https://static1.twitcount.com/js/button.js"></script>};

    return $js;
}

1;
