use Cwd;
use File::Spec;
use POSIX;
use MIME::Base64;
use File::Temp qw(tempfile tempdir);
use Archive::Zip;
use Digest::MD5 qw(md5_hex);

my $dir = getcwd;
my $logfile ="";
my $pluginDir;


if ( defined $ENV{QUERY_STRING} ) {    # Promotion through UI
    $pluginDir = $ENV{COMMANDER_PLUGINS} . "/$pluginName";
}
else {
    my $commanderPluginDir = $commander->getProperty('/server/settings/pluginsDirectory')->findvalue('//value');
    # We are not checking for the directory, because we can run this script on a different machine
    $pluginDir = File::Spec->catfile($commanderPluginDir, $pluginName);
}

$logfile .= "Plugin directory is $pluginDir";

$commander->setProperty("/plugins/$pluginName/project/pluginDir", {value=>$pluginDir});
$logfile .= "Plugin Name: $pluginName\n";
$logfile .= "Current directory: $dir\n";

# Evaluate promote.groovy or demote.groovy based on whether plugin is being promoted or demoted ($promoteAction)
local $/ = undef;
# If env variable QUERY_STRING exists:
my $dslFilePath;
if(defined $ENV{QUERY_STRING}) { # Promotion through UI
    $dslFilePath = File::Spec->catfile($ENV{COMMANDER_PLUGINS}, $pluginName, "dsl", "$promoteAction.groovy");
} else {  # Promotion from the command line
    $dslFilePath = File::Spec->catfile($pluginDir, "dsl", "$promoteAction.groovy");
}

my $demoteDsl = q{
# demote.groovy placeholder
};
my $promoteDsl = q{
# promote.groovy placeholder
};


my $dsl;
if ($promoteAction eq 'promote') {
  $dsl = $promoteDsl;
}
else {
  $dsl = $demoteDsl;
}

my $dslReponse = $commander->evalDsl(
    $dsl, {
        parameters => qq(
                     {
                       "pluginName":"$pluginName",
                       "upgradeAction":"$upgradeAction",
                       "otherPluginName":"$otherPluginName"
                     }
              ),
        debug             => 'false',
        serverLibraryPath => File::Spec->catdir( $pluginDir, 'dsl' ),
    },
);

$logfile .= $dslReponse->findnodes_as_string("/");
my $errorMessage = $commander->getError();

if ( !$errorMessage ) {
    # This is here because we cannot do publishArtifactVersion in dsl today
    # delete artifact if it exists first

    my $dependenciesProperty = '/projects/@PLUGIN_NAME@/ec_groovyDependencies';
    my $base64 = '';
    my $xpath;
    eval {
      $xpath = $commander->getProperties({path => $dependenciesProperty});
      1;
    };
    unless($@) {
      my $blocks = {};
      my $checksum = '';
      for my $prop ($xpath->findnodes('//property')) {
        my $name = $prop->findvalue('propertyName')->string_value;
        my $value = $prop->findvalue('value')->string_value;
        if ($name eq 'checksum') {
          $checksum = $value;
        }
        else {
          my ($number) = $name =~ /ec_dependencyChunk_(\d+)$/;
          $blocks->{$number} = $value;
        }
      }
      for my $key (sort {$a <=> $b} keys %$blocks) {
        $base64 .= $blocks->{$key};
      }

      my $resultChecksum = md5_hex($base64);
      unless($checksum) {
        die "No checksum found in dependendencies property, please reinstall the plugin";
      }
      if ($resultChecksum ne $checksum) {
        die "Wrong dependency checksum: original checksum is $checksum";
      }
    }

  if ($base64) {
    my $grapesVersion = '1.0.0';
    my $cleanup = 1;
    my $groupId = 'com.electriccloud';
    $commander->deleteArtifactVersion($groupId . ':@PLUGIN_KEY@-Grapes:' . $grapesVersion);
    my $binary = decode_base64($base64);
    my ($tempFh, $tempFilename) = tempfile(CLEANUP => $cleanup);
    binmode($tempFh);
    print $tempFh $binary;
    close $tempFh;

    my ($tempDir) = tempdir(CLEANUP => $cleanup);
    my $zip = Archive::Zip->new();
    unless($zip->read($tempFilename) == Archive::Zip::AZ_OK()) {
      die "Cannot read .zip dependencies: $!";
    }
    $zip->extractTree("", File::Spec->catfile($tempDir, ''));

    if ( $promoteAction eq "promote" ) {
        #publish jars to the repo server if the plugin project was created successfully
        my $am = new ElectricCommander::ArtifactManagement($commander);
        my $artifactVersion = $am->publish(
            {   groupId         => $groupId,
                artifactKey     => '@PLUGIN_KEY@-Grapes',
                version         => $grapesVersion,
                includePatterns => "**",
                fromDirectory   => "$tempDir/lib/grapes",
                description => 'JARs that @PLUGIN_KEY@ plugin procedures depend on'
            }
        );

        # Print out the xml of the published artifactVersion.
        $logfile .= $artifactVersion->xml() . "\n";
        if ( $artifactVersion->diagnostics() ) {
            $logfile .= "\nDetails:\n" . $artifactVersion->diagnostics();
        }
    }
  }
}


# Create output property for plugin setup debug logs
my $nowString = localtime;
$commander->setProperty( "/plugins/$pluginName/project/logs/$nowString", { value => $logfile } );

die $errorMessage unless !$errorMessage;

my $unView =
'<view>
  <base>Default</base>
  <tab>
    <label>Home</label>
    <tab>
      <label>Un</label>
      <position>3</position>
      <url>pages/@PLUGIN_KEY@/un_run</url>
    </tab>
  </tab>
</view>';

my $unViewAll =
'<view>
  <base>Default</base>
  <tab>
    <label>UnTab</label>
    <position>2</position>
    <tab>
      <label>Un1</label>
      <position>1</position>
      <url>pages/@PLUGIN_KEY@/un_run1</url>
    </tab>
    <tab>
      <label>Un2</label>
      <position>2</position>
      <url>pages/@PLUGIN_KEY@/un_run2</url>
    </tab>
    <tab>
      <label>Un3</label>
      <position>3</position>
      <url>pages/@PLUGIN_KEY@/un_run3</url>
    </tab>
    <tab>
      <label>Un4</label>
      <position>4</position>
      <url>pages/@PLUGIN_KEY@/un_run4</url>
    </tab>
    <tab>
      <label>Un5</label>
      <position>5</position>
      <url>pages/@PLUGIN_KEY@/un_run5</url>
    </tab>
    <tab>
      <label>Un6</label>
      <position>6</position>
      <url>pages/@PLUGIN_KEY@/un_run6</url>
    </tab>
    <tab>
      <label>Un7</label>
      <position>7</position>
      <url>pages/@PLUGIN_KEY@/un_run7</url>
    </tab>
    <tab>
      <label>Un8</label>
      <position>8</position>
      <url>pages/@PLUGIN_KEY@/un_run8</url>
    </tab>
  </tab>
</view>';

if ($promoteAction eq 'promote') {
    # Use createProperty (and ignore errors) so that we do not overwrite existing properties
    $commander->abortOnError(0);
    $commander->createProperty("/server/@PLUGIN_KEY@/v",
	{description=>'Content to be displayed by the @PLUGIN_KEY@ plugin main page',
	 value=>'$' . '[/plugins/@PLUGIN_KEY@/project/v_example2]',
	 expandable=>'1'});
    foreach my $i (0 .. 9, "a" .. "z") {
      $commander->createProperty("/server/@PLUGIN_KEY@/v$i", {
        description=>"Content to be displayed by the @PLUGIN_KEY@ plugin subpage $i",
	       value=>'$' . '[/plugins/@PLUGIN_KEY@/project/v_example' . $i . ']',
	        expandable=>'1'
        });
    }
    foreach my $i ('flot', 'jquery', 'unplug') {
	    $commander->createProperty("/server/@PLUGIN_KEY@/lib/use-$i", {
	       description=>"XHTML fragment to pull in the $i javascript libraries and dependencies",
	       value=>'$' . '[/plugins/@PLUGIN_KEY@/project/lib/use-' . $i . ']',
	       expandable=>'1'});
    }
    # Reset error handling at this point
    $commander->abortOnError(1);
    $commander->setProperty("/server/@PLUGIN_KEY@/unplug_doUrl",
		     {description=>"URL for the unplug AJAX helper CGI",
		      value=>'/commander/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/cgi-bin/do.cgi',
		      expandable=>'0'});
    $commander->setProperty("/server/ec_ui/availableViews/unView",
		     {description=>'Unplug View', value=>$unView});
    $commander->setProperty("/server/ec_ui/availableViews/unViewAll",
		     {description=>'Unplug View, Top-level with sub-tabs', value=>$unViewAll});

  # Run DSL to create procedures to add and remove Unplug page menus to Flow menu
 	my $xp = $commander->getProperty("/projects/${pluginName}/AddFullMenuToFlow");
 	my $AddFullMenuToFlow = $xp->findvalue('/responses/response/property/value')->value();
 	$commander->evalDsl({dsl => "$AddFullMenuToFlow",parameters=>qq(
                      {
                            "pluginName":"$pluginName"
                      }
               )});
	# Run the procedure that adds Unplug menus to Flow menus
	$commander->runProcedure({projectName=>$pluginName, procedureName=>"Add Unplug to Flow Menu"});
	$commander->runProcedure({projectName=>$pluginName, procedureName=>"Add Unplug to Commander Menu"});
} elsif ($promoteAction eq 'demote') {
    $batch->deleteProperty("/server/ec_ui/availableViews/unView");
    $batch->deleteProperty("/server/ec_ui/availableViews/unViewAll");

	# Run the procedure that removes Unplug menus to Flow menus
	$commander->runProcedure({projectName=>$pluginName, procedureName=>"Remove Unplug from Flow Menu"});
	$commander->runProcedure({projectName=>$pluginName, procedureName=>"Remove Unplug from Commander Menu"});
}
