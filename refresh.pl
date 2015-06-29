#!/usr/bin/perl -w
use strict;

use WWW::Mechanize;
use Carp;
use File::Basename;
use File::Spec;
use File::Path qw(make_path);

my $root_dir = $ENV{PWD};

unless ( -f File::Spec->catfile( $root_dir, $0 ) ) {
    confess "Could not find $0 in directory $root_dir";
}

my $mech = WWW::Mechanize->new();
my $leginfo_rcw_template =
  'http://apps.leg.wa.gov/rcw/default.aspx?Cite=%s&full=true#';

my ( $title, $chapter, $section );
my $citation = $ARGV[0];

if ($citation) {
    ( $title, $chapter, $section ) = ( split( /\./, $citation ) );
}
else {
    $title   = 26;
    $chapter = 4;
    $section = 20;

    $citation = sprintf( '%d.%02d.%03d', $title, $chapter, $section );
}

my $rcw_url = sprintf( $leginfo_rcw_template, $citation );

$mech->get($rcw_url);
print "fetched url: $rcw_url\n";

my $html_path = get_local_path(
    {
        title   => $title,
        chapter => $chapter,
        section => $section
    }
);

my ( $html_filename, $directory, $extension ) = fileparse($html_path);

File::Path::make_path($directory);

$mech->save_content($html_path);

print "exported HTML: $html_path\n";

my($txt_filename) = $html_filename;
$txt_filename =~ s/html$/txt/;

my $txt_path = File::Spec->catfile( $directory, $txt_filename );
my $links = '/usr/bin/links';

my $cmd = qq{${links} -dump ${html_path}};

my @text = split(/^/m,`$cmd`);

while( my $line = shift @text ){
	next unless $line =~ /^\s+Access Washington/;
	unshift( @text, $line );
	last;
}

open( my $txt_fh, q{>}, $txt_path ) or die "couldn't open $txt_path for writing";

print $txt_fh @text;

print "converted to txt: $txt_path\n";

unlink( $html_path );

sub get_local_path {
    my ($opt) = @_;

    my $title = $opt->{title};
    my $chapter = sprintf( '%d.%02d', $opt->{title}, $opt->{chapter} );
    my $section =
      sprintf( '%d.%02d.%03d', $opt->{title}, $opt->{chapter},
        $opt->{section} );

    my @path;
    if (   defined $opt->{section}
        && defined $opt->{chapter}
        && defined $opt->{title} )
    {
        @path = ( 'title', $title, 'chapter', $chapter, 'section',
            "${section}.html" );
    }
    elsif (defined $opt->{chapter}
        && defined $opt->{title} )
    {
        @path = ( 'title', $title, 'chapter', $chapter, 'index.html' );
    }
    elsif ( defined $opt->{title} ) {
        @path = ( 'title', $title, 'index.html' );
    }
    else {
        confess("incorrect options were passed to get_local_path");
    }

    my $path = File::Spec->catfile( $root_dir, @path );

}
