# Unplug
_An Essential Tool for Rapid Plugin Development_

## Overview
  This plugin is a completely flexible plugin framework that displays a
page built from content read from an ElectricCommander property.

  Typical uses include implementing a simple "News of the Day" or status
page for ElectricCommander users, performing rapid prototyping of plugin
logic as well as plugin presentation, and serving as a training aid to
speed learning about ElectricCommander plugins and how they work.

## Quick Installation

  Download the plugin jar file, then install and promote the plugin in
the normal fashion.  Once promoted, click on your user name (in the
upper right corner of the Commander Web UI), and select "Edit Settings"
on your User Details page.  Select "Unplug View" from the "Tab View"
list box, and click "OK".  A new sub-tab (named "Un") should appear
beneath your normal Home tab in the UI.

There are procedures provided to add Unplug pages to the Flow and Commander
UIs. These procedures add all the examples in the Unplug plugin plus any
user-created ones saved to the properties /server/unplug/{v,v0-9,va-z}.

## build
<p>To build the plugin, you will need to have first to build
  <a href="https://github.com/electric-cloud/ecpluginbuilder">ecpluginbuilder</a>
  for your platform.<br/>

  Then simply:
  <ul>
    <li>log into your Flow server with "ectool --server SERVER login USER PWD"</li>
    <li>run "ec-perl ecpluginbuilder.pl", the tool will:
      <ul>
        <li>increment the build counter (main version can be changed in the script or with the -version option)</li>
        <li>build the plugin</li>
        <li>install the plugin</li>
        <li>promote the plugin</li>
      </ul>  
    </li>
    </ul>
</p>


## Obtaining Help

  Help documentation is available from the normal "Help" link (top-right
corner on the GUI) when viewing the "Un" tab.  The provided examples
are briefly described by the help documentation, but the source code for
the examples is even more helpful.  You can navigate to the plugin
project to find the properties containing the source code for the examples,
but it's better to use "ectool" to copy the source code out to a file
as described in the help text for the plugin.

  Additional help (and eventually examples) is available through the
http://ask.electric-cloud.com/ forum -- post your questions, concerns,
comments, example, feedback, criticism, and complaints.
