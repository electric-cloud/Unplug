#!/bin/sh

exec "$COMMANDER_HOME/bin/ec-perl" -x "$0" "${@}"

#!perl

use strict;
use ElectricCommander;
use ElectricCommander::Util;
use XML::Parser;
use XML::XPath;
use URI::Escape;
use CGI;

use utf8;
ElectricCommander::initEncodings();

my $HTML = '';
my $XHTML = '';

# Can't get the CGI lib to fetch POSTDATA, so do it ourselves:
my $raw;
read(STDIN, $raw, $ENV{'CONTENT_LENGTH'});

# Create the CGI object we'll need later on.
my $cgi = new CGI;

my $v = '';

# Test if the "v=..." parameter was specified in the URL
my $pn = $cgi->url_param('v');
$pn = $cgi->url_param('V') unless ($pn); # case-insensitive, for sloppy users
if ($pn) {

    # We have a property path - read property ourselves
    my $ec = ElectricCommander->new({'abortOnError'=>0});

    # Permit certain sloppiness in the property path passed in
    $pn =~ s|^/server/unplug/||;    # be lenient with over-spec'ing
    $pn =~ s|^/||;                  # get rid of leading slash

    # Fetch property and extract result (including error, if present)
    my $xp = $ec->getProperty('/server/unplug/' . $pn);
    #$v = "DEBUG\n" . $xp->findnodes_as_string("/") . "\n";
    if ($xp->findvalue('/responses/error/code')->value()) {

        # Oops, went wrong - so kraft an error message to display
        $v .= "<!-- HTML -->\n" .
              '<h1>Error</h1>' .
              '<p/><b>Code:&#160;&#160;</b>' .
              CGI::escapeHTML($xp->findvalue('/responses/error/code')->value()) .
              '<p/><b>Message:&#160;&#160;</b>' .
              CGI::escapeHTML($xp->findvalue('/responses/error/message')->value()) .
              '<p/><b>Details:</b><br/><pre>' .
              CGI::escapeHTML($xp->findvalue('/responses/error/details')->value()) .
              '</pre>';
    } else {

        # Property read and expanded ok, fetch the value
        $v .= $xp->findvalue('/responses/response/property/value')->value();
    }

} else {

    # Extract the property value from the XML posted to our STDIN.
    my $xp = new XML::XPath($raw);
    $v = $xp->findvalue('/responses/response[@requestId="v"]/property/value');

}

# Use some hueristics to try to guess file content.
my $c = ($v =~ m|^(.*?)$|ms)[0];

if ($c=~ m|^\s*\<.*xhtml.*\>|i) {
    # XHTML, pass through literally
    $XHTML = $v;

} elsif ($c=~ m|^\s*\<.*html.*\>|i) {
    # HTML, pass through literally
    $HTML = $v;

} elsif ($c=~ m|^\s*\#\!.*perl|i) {
    # Send standard output to the standard error stream
    # (which is normally the Apache log file for a plugin)
    open(TMPOUT, ">&STDOUT");
    open(STDOUT, '>&STDERR');
    # Compile and execute the Perl code
    eval "$v";
    # Test for any error messages from the eval
    if ($@) {
        $HTML = "<h1>Error</h1><p/><pre>" . 
                 CGI::escapeHTML($@) . "\n</pre>";
        $XHTML = '';
    }
    # Put standard output back the correct way
    open(STDOUT, ">&TMPOUT");

} elsif ($c=~ m|^\s*//.*dsl|i) {
	# Create a Commander API handle
    my $ec = ElectricCommander->new({'abortOnError'=>0});
    # Run the DSL code
	my $dslResponse = $ec->evalDsl("$v")->findvalue('/responses')->value();
	# Trim everything after </html>
	foreach my $line (split /^/m, $dslResponse) {
	   $HTML .= $line;
	   if ($line =~ m/<\/html>/) {last};
	}
	
} elsif ($v) {
    # Normal (plain) text was provided, wrap in <pre> tags.
    # (Note: the leading space here is required for MS IE6)
    $HTML = " <pre>" . CGI::escapeHTML($v) . "</pre>\n";
}

# If XHTML, then test for well-formed-ness.
if ($XHTML) {
    my $p = XML::Parser->new(ErrorContext=>2);
    eval { $p->parse("<body>$XHTML</body>"); };
    if ($@) {
        $HTML = "<h1>Warning</h1><p/><pre>XHTML is not well-formed: " .
                 CGI::escapeHTML($@) . "\n</pre><hr>$XHTML";
        $XHTML = '';
    }
}

# Test for an empty document (usually unintended).
$HTML = "<h1>Warning</h1><p/><pre>Empty HTML document.\n</pre>"
    unless (($XHTML) || ($HTML));

# Print correct HTTP header, then the content, and the closing tags.
if ($HTML) {
    print $cgi->header('-type'=>'text/html', '-encoding'=>'UTF-8', getNoCache());
    print "<html><body>$HTML</body></html>\n";
} else {
    print $cgi->header('-type'=>'application/xhtml+xml', '-encoding'=>'UTF-8', getNoCache());
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"";
    print " \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n";
    print "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">";
    print "<body>$XHTML</body></html>\n";
}

exit(0);
