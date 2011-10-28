#!/usr/bin/perl
package IkiWiki::Plugin::ymlfront;
use warnings;
use strict;
=head1 NAME

IkiWiki::Plugin::ymlfront - add YAML-format data to a page

=head1 VERSION

This describes version B<1.20110610> of IkiWiki::Plugin::ymlfront

=cut

our $VERSION = '1.20110610';

=head1 DESCRIPTION

This allows field-data to be defined in YAML format on a page.
This is a back-end for the "field" plugin.

See doc/plugins/contrib/ymlfront and ikiwiki/directive/ymlfront for docs.

=head1 PREREQUISITES

    IkiWiki
    IkiWiki::Plugin::field
    YAML::Any

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    http://github.com/rubykat

=head1 COPYRIGHT

Copyright (c) 2009-2011 Kathryn Andersen

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
use IkiWiki 3.00;

sub import {
	hook(type => "getsetup", id => "ymlfront", call => \&getsetup);
	hook(type => "checkconfig", id => "ymlfront", call => \&checkconfig);
	hook(type => "filter", id => "ymlfront", call => \&filter, first=>1);
	hook(type => "preprocess", id => "ymlfront", call => \&preprocess, scan=>1);
    #hook(type => "scan", id => "ymlfront", call => \&scan);
	hook(type => "checkcontent", id => "ymlfront", call => \&checkcontent);

	IkiWiki::loadplugin('field');
	IkiWiki::Plugin::field::field_register(id=>'ymlfront',
					       all_values=>\&yml_get_values,
					       first=>1);
}

# ------------------------------------------------------------
# Hooks
# --------------------------------
sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => 1,
		},
		ymlfront_delim => {
			type => "array",
			example => "ymlfront_delim => [qw(--YAML-START-- --YAML-END--)]",
			description => "delimiters of YAML data",
			safe => 0,
			rebuild => undef,
		},
		ymlfront_set_content => {
			type => "boolean",
			example => "ymlfront_set_content => 1",
			description => "allow ymlfront to define the content of the page inside the YAML",
			safe => 0,
			rebuild => undef,
		},
}

sub checkconfig () {
    eval {use YAML::Any};
    eval {use YAML} if $@;
    if ($@)
    {
	return error ("ymlfront: failed to use YAML::Any or YAML");
    }

    $YAML::UseBlock = 1;
    $YAML::Syck::ImplicitUnicode = 1;

    if (!defined $config{ymlfront_delim})
    {
	$config{ymlfront_delim} = [qw(--- ---)];
    }
    if (!defined $config{ymlfront_set_content})
    {
	$config{ymlfront_set_content} = 0;
    }
} # checkconfig

sub scan (@) {
    my %params=@_;
    my $page = $params{page};

    my $page_file=$pagesources{$page} || return;
    my $page_type=pagetype($page_file);
    if (!defined $page_type)
    {
	return;
    }
    my $extracted_yml = extract_yml(%params);
    if (defined $extracted_yml
	and defined $extracted_yml->{yml})
    {
	my $parsed_yml = parse_yml(%params, data=>$extracted_yml->{yml});
	if (defined $parsed_yml)
	{
	    # clear the old data
	    if (exists $pagestate{$page}{ymlfront})
	    {
		delete $pagestate{$page}{ymlfront};
	    }
	    # save the data to pagestate
	    foreach my $fn (keys %{$parsed_yml})
	    {
		my $fval = $parsed_yml->{$fn};
		$pagestate{$page}{ymlfront}{$fn} = $fval;
	    }
	    # update meta hash
	    if (exists $pagestate{$page}{ymlfront}{title}
		and $pagestate{$page}{ymlfront}{title})
	    {
		$pagestate{$page}{meta}{title} = $pagestate{$page}{ymlfront}{title};
	    }
	    if (exists $pagestate{$page}{ymlfront}{description}
		and $pagestate{$page}{ymlfront}{description})
	    {
		$pagestate{$page}{meta}{description} = $pagestate{$page}{ymlfront}{description};
	    }
	    if (exists $pagestate{$page}{ymlfront}{author}
		and $pagestate{$page}{ymlfront}{author})
	    {
		$pagestate{$page}{meta}{author} = $pagestate{$page}{ymlfront}{author};
	    }
	}
    }
} # scan

# use this for data in a [[!ymlfront ...]] directive
sub preprocess (@) {
    my %params=@_;
    my $page = $params{page};

    if (! exists $params{data}
	or ! defined $params{data}
	or !$params{data})
    {
	error gettext("missing data parameter")
    }
    # All the work of this is done in scan mode;
    # when in preprocessing mode, just return an empty string.
    my $scan=! defined wantarray;

    if (!$scan)
    {
	return '';
    }

    # clear the old data
    if (exists $pagestate{$page}{ymlfront})
    {
	delete $pagestate{$page}{ymlfront};
    }
    my $parsed_yml = parse_yml(%params);
    if (defined $parsed_yml)
    {
	# clear the old data
	if (exists $pagestate{$page}{ymlfront})
	{
	    delete $pagestate{$page}{ymlfront};
	}
	# save the data to pagestate
	foreach my $fn (keys %{$parsed_yml})
	{
	    my $fval = $parsed_yml->{$fn};
	    $pagestate{$page}{ymlfront}{$fn} = $fval;
	}
	# update meta hash
	if (exists $pagestate{$page}{ymlfront}{title}
	    and $pagestate{$page}{ymlfront}{title})
	{
	    $pagestate{$page}{meta}{title} = $pagestate{$page}{ymlfront}{title};
	}
	if (exists $pagestate{$page}{ymlfront}{description}
	    and $pagestate{$page}{ymlfront}{description})
	{
	    $pagestate{$page}{meta}{description} = $pagestate{$page}{ymlfront}{description};
	}
	if (exists $pagestate{$page}{ymlfront}{author}
	    and $pagestate{$page}{ymlfront}{author})
	{
	    $pagestate{$page}{meta}{author} = $pagestate{$page}{ymlfront}{author};
	}
    }
    else
    {
	error gettext("ymlfront: data not legal YAML")
    }
    return '';
} # preprocess

sub filter (@) {
    my %params=@_;
    my $page = $params{page};

    my $page_file=$pagesources{$page} || return $params{content};
    my $page_type=pagetype($page_file);
    if (!defined $page_type)
    {
	return $params{content};
    }
    my $extracted_yml = extract_yml(%params);
    if (defined $extracted_yml
	and defined $extracted_yml->{yml}
	and defined $extracted_yml->{content})
    {
	$params{content} = $extracted_yml->{content};
	# check for a content value
	if ($config{ymlfront_set_content}
	    and exists $pagestate{$page}{ymlfront}{content}
	    and defined $pagestate{$page}{ymlfront}{content}
	    and $pagestate{$page}{ymlfront}{content})
	{
	    $params{content} .= $pagestate{$page}{ymlfront}{content};
	}
    }

    return $params{content};
} # filter

# check the correctness of the YAML code before saving a page
sub checkcontent {
    my %params=@_;
    my $page = $params{page};

    my $page_file=$pagesources{$page};
    if ($page_file)
    {
	my $page_type=pagetype($page_file);
	if (!defined $page_type)
	{
	    return undef;
	}
    }
    my $extracted_yml = extract_yml(%params);
    if (defined $extracted_yml
	and !defined $extracted_yml->{yml})
    {
	debug("ymlfront: Save of $page failed: $@");
	return gettext("YAML data incorrect: $@");
    }
    return undef;
} # checkcontent

# ------------------------------------------------------------
# Field functions
# --------------------------------
sub yml_get_values (@) {
    my %params=@_;
    my $page = $params{page};

    my $page_file=$pagesources{$page} || return;
    my $page_type=pagetype($page_file);
    if (!defined $page_type)
    {
	return;
    }
    my $extracted_yml = extract_yml(%params);
    if (defined $extracted_yml
	and defined $extracted_yml->{yml})
    {
	my $parsed_yml = parse_yml(%params, data=>$extracted_yml->{yml});
	return $parsed_yml;
    }
    return undef;
} # yml_get_values

sub yml_get_value ($$) {
    my $field_name = shift;
    my $page = shift;

    my $value = undef;
    if (exists $pagestate{$page}{ymlfront}{$field_name})
    {
	$value = $pagestate{$page}{ymlfront}{$field_name};
    }
    elsif (exists $pagestate{$page}{ymlfront}{lc($field_name)})
    {
	$value = $pagestate{$page}{ymlfront}{lc($field_name)};
    }
    if (defined $value)
    {
	if (ref $value)
	{
	    my @value_array = @{$value};
	    return (wantarray
		    ? @value_array
		    : join(",", @value_array));
	}
	else
	{
	    return (wantarray ? ($value) : $value);
	}
    }
    return undef;
} # yml_get_value

# ------------------------------------------------------------
# Helper functions
# --------------------------------

# extract the YAML data from the given content
# Expects page, content
# Returns { yml=>$yml_str, content=>$content } or undef
# if undef is returned, there is no YAML
# but if $yml_str is undef then there was YAML but it was not legal
sub extract_yml {
    my %params=@_;
    my $page = $params{page};
    my $content = $params{content};

    my $page_file=$pagesources{$page};
    if ($page_file)
    {
	my $page_type=pagetype($page_file);
	if (!defined $page_type)
	{
	    return undef;
	}
    }
    my $start_of_content = '';
    my $yml_str = '';
    my $rest_of_content = '';
    if ($content)
    {
	my $ystart = $config{ymlfront_delim}[0];
	my $yend = $config{ymlfront_delim}[1];
	if ($ystart eq '---' and $yend eq '---')
	{
	    if ($content =~ /^---[\n\r](.*?[\n\r])---[\n\r](.*)$/s)
	    {
		$yml_str = $1;
		$rest_of_content = $2;
	    }
	}
	elsif ($content =~ /^(.*?)${ystart}[\n\r](.*?[\n\r])${yend}([\n\r].*)$/s)
	{
	    $yml_str = $2;
	    $rest_of_content = $1 . $3;
	} 
    }
    if ($yml_str) # possible YAML
    {
	# if {{$page}} is there, do an immediate substitution
	$yml_str =~ s/\{\{\$page\}\}/$page/sg;

	my $ydata;
	eval {$ydata = Load($yml_str);};
	if ($@)
	{
	    debug("ymlfront: Load of $page data failed: $@");
	    return { yml=>undef, content=>$content };
	}
	if (!$ydata)
	{
	    debug("ymlfront: no legal YAML for $page");
	    return { yml=>undef, content=>$content };
	}
	return { yml=>$yml_str,
	    content=>$start_of_content . $rest_of_content};
    }
    return undef;
} # extract_yml

# parse the YAML data from the given string
# Expects page, data
# Returns \%yml_data or undef
sub parse_yml {
    my %params=@_;
    my $page = $params{page};
    my $yml_str = $params{data};

    if ($yml_str)
    {
       $yml_str .= "\n"; # whatever gets the data here strips all trailing whitespace, so this needs to be added

	# if {{$page}} is there, do an immediate substitution
	$yml_str =~ s/\{\{\$page\}\}/$page/sg;

	my $ydata;
	eval {$ydata = Load($yml_str);};
	if ($@)
	{
	    debug("ymlfront parse: Load of $page data failed: $@");
	    return undef;
	}
	if (!$ydata)
	{
	    debug("ymlfront parse: no legal YAML for $page");
	    return undef;
	}
	if ($ydata)
	{
	    my %lc_data = ();

	    # make lower-cased versions of the data
	    foreach my $fn (keys %{$ydata})
	    {
		my $fval = $ydata->{$fn};
		$lc_data{lc($fn)} = $fval;
	    }
	    return \%lc_data;
	}
    }
    return undef;
} # parse_yml
1;
