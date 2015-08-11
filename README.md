# Rackspace Monitoring Agent Custom Plugins

This repository contains contributed custom plugins for the Rackspace Cloud
Monitoring agent. For details about installing plugins, see [agent plugin check documentation](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/appendix-check-types-agent.html#section-ct-agent.plugin).

## Plugin Requirements

Each plugin must fulfill the following properties:

  * Output a status message to STDOUT
  * Output one or more metrics if it succeeds in obtaining them to STDOUT
  * Contain an appropriate license header
  * Contain example alarm criteria

## Status

The status message should be of the form <code>status $status_string</code>, For example, it might be:

<code>status ok succeeded in obtaining metrics</code>

or

<code> status err failed to obtain metrics</code>

The status string should be a summary of the results, with actionable information if it fails.

## Metrics

The metrics message should be of the form <code>metric $name $type $value [unit]</code>, for example:

<code>metric time int32 1 seconds</code>

The units are optional, and if present should be a string representing the units of the metric measurement. Units may not be provided on string metrics, and may not contain any spaces.

The available types are:

  * string
  * float
  * double
  * int32
  * int64
  * uint32
  * uint64
  * gauge

## Alarm Criteria

Each script should contain, just below the license header, in a comment, an example alarm criteria that can be used for the plugin. See the [Rackspace Cloud Monitoring Documentation](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/alerts-language.html#concepts-alarms-alarm-language) for how to write alarm criteria.