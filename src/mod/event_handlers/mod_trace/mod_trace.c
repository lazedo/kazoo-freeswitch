/*
 * FreeSWITCH Modular Media Switching Software Library / Soft-Switch Application
 * Copyright (C) 2005-2014, Anthony Minessale II <anthm@freeswitch.org>
 *
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is FreeSWITCH Modular Media Switching Software Library / Soft-Switch Application
 *
 * The Initial Developer of the Original Code is
 * Anthony Minessale II <anthm@freeswitch.org>
 * Portions created by the Initial Developer are Copyright (C)
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * James Aimonetti <james@2600hz.com>
 *
 * mod_trace.c -- Framework Demo Module
 *
 */
#include <switch.h>

/* Prototypes */
SWITCH_MODULE_SHUTDOWN_FUNCTION(mod_trace_shutdown);
SWITCH_MODULE_RUNTIME_FUNCTION(mod_trace_runtime);
SWITCH_MODULE_LOAD_FUNCTION(mod_trace_load);

typedef enum {
  EVENT_FORMAT_PLAIN,
  EVENT_FORMAT_XML,
  EVENT_FORMAT_JSON
} event_format_t;

static struct {
  switch_event_node_t *node;
  event_format_t format;
} globals;

static void trace_handler(switch_event_t *event)
{
  char* trace_event;
  char *buf;

  switch_assert(event != NULL);

  if ( !(trace_event = switch_event_get_header(event, "variable_trace_event")) ) {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "ignore event %s\n", switch_event_name(event->event_id));
    return;
  }

  if ( switch_false(trace_event) ) {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "trace event was %s\n", trace_event);
    return;
  }

  switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "tracing event %s\n", switch_event_name(event->event_id));

  switch(globals.format) {
  case EVENT_FORMAT_PLAIN:
    break;
  case EVENT_FORMAT_XML:
    break;
  case EVENT_FORMAT_JSON:
  default:
    if (switch_event_serialize_json(event, &buf) == SWITCH_STATUS_SUCCESS) {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "serialized event %s to json: %s\n", switch_event_name(event->event_id), buf);
    } else {
      switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_DEBUG, "failed to serialize event %s\n", switch_event_name(event->event_id));
    }
    break;
  }

  return;
}

/* SWITCH_MODULE_DEFINITION(name, load, shutdown, runtime)
 * Defines a switch_loadable_module_function_table_t and a static const char[] modname
 */
SWITCH_MODULE_DEFINITION(mod_trace, mod_trace_load, mod_trace_shutdown, NULL);

/* Macro expands to: switch_status_t mod_trace_load(switch_loadable_module_interface_t **module_interface, switch_memory_pool_t *pool) */
SWITCH_MODULE_LOAD_FUNCTION(mod_trace_load)
{
  /* connect my internal structure to the blank pointer passed to me */
  *module_interface = switch_loadable_module_create_module_interface(pool, modname);

  memset(&globals, 0, sizeof(globals));

  globals.format = EVENT_FORMAT_JSON;

  if (switch_event_bind_removable(modname, SWITCH_EVENT_ALL, SWITCH_EVENT_SUBCLASS_ANY, trace_handler, NULL, &globals.node) != SWITCH_STATUS_SUCCESS) {
    switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_ERROR, "Couldn't bind!\n");
    return SWITCH_STATUS_GENERR;
  }

  /* indicate that the module should continue to be loaded */
  return SWITCH_STATUS_SUCCESS;
}

/*
  Called when the system shuts down
  Macro expands to: switch_status_t mod_trace_shutdown()
*/
SWITCH_MODULE_SHUTDOWN_FUNCTION(mod_trace_shutdown)
{
  switch_event_unbind(&globals.node);
  return SWITCH_STATUS_SUCCESS;
}
