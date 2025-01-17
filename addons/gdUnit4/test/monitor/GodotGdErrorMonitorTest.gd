# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GodotGdErrorMonitorTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/monitor/GodotGdErrorMonitor.gd'


const error_report = """
	USER ERROR: this is an error
	   at: push_error (core/variant/variant_utility.cpp:880)
	"""
const script_error = """
	USER SCRIPT ERROR: Trying to call a function on a previously freed instance.
	   at: GdUnitScriptTypeTest.test_xx (res://addons/gdUnit4/test/GdUnitScriptTypeTest.gd:22)
"""


func test_parse_script_error_line_number() -> void:
	var line := GodotGdErrorMonitor._parse_error_line_number(script_error.dedent())
	assert_int(line).is_equal(22)


func test_parse_push_error_line_number() -> void:
	var line := GodotGdErrorMonitor._parse_error_line_number(error_report.dedent())
	assert_int(line).is_equal(-1)


func test_scan_for_push_errors() -> void:
	var monitor := mock(GodotGdErrorMonitor, CALL_REAL_FUNC) as GodotGdErrorMonitor
	monitor._report_enabled = true
	do_return(error_report.dedent().split('\n')).on(monitor)._collect_log_entries()
	
	# with disabled push_error reporting
	do_return(false).on(monitor)._is_report_push_errors()
	assert_array(monitor.reports()).is_empty()
	
	# with enabled push_error reporting
	do_return(true).on(monitor)._is_report_push_errors()
	
	var expected_report := GodotGdErrorMonitor._report_user_error("USER ERROR: this is an error", "at: push_error (core/variant/variant_utility.cpp:880)")
	assert_array(monitor.reports()).contains_exactly([expected_report])


func test_scan_for_script_errors() -> void:
	var monitor := mock(GodotGdErrorMonitor, CALL_REAL_FUNC) as GodotGdErrorMonitor
	monitor._report_enabled = true
	do_return(script_error.dedent().split('\n')).on(monitor)._collect_log_entries()
	
	# with disabled push_error reporting
	do_return(false).on(monitor)._is_report_script_errors()
	assert_array(monitor.reports()).is_empty()
	
	# with enabled push_error reporting
	do_return(true).on(monitor)._is_report_script_errors()
	
	var expected_report := GodotGdErrorMonitor._report_runtime_error("USER SCRIPT ERROR: Trying to call a function on a previously freed instance.",\
		"at: GdUnitScriptTypeTest.test_xx (res://addons/gdUnit4/test/GdUnitScriptTypeTest.gd:22)")
	assert_array(monitor.reports()).contains_exactly([expected_report])


func test_custom_log_path() -> void:
	# save original log_path
	var log_path :String = ProjectSettings.get_setting("debug/file_logging/log_path")
	# set custom log path
	var custom_log_path := "user://logs/test-run.log"
	FileAccess.open(custom_log_path, FileAccess.WRITE).store_line("test-log")
	ProjectSettings.set_setting("debug/file_logging/log_path", custom_log_path)
	var monitor := GodotGdErrorMonitor.new()
	
	assert_that(monitor._godot_log_file).is_equal(custom_log_path)
	# restore orignal log_path
	ProjectSettings.set_setting("debug/file_logging/log_path", log_path)


func test_integration_test() -> void:
	var monitor := GodotGdErrorMonitor.new(true)
	# no errors reported
	monitor.start()
	monitor.stop()
	assert_array(monitor.reports()).is_empty()
	
	# push error
	monitor.start()
	push_error("Test GodotGdErrorMonitor 'push_error' reporting")
	monitor.stop()
	assert_array(monitor.reports()).is_not_empty()
	if not monitor.reports().is_empty():
		assert_str(monitor.reports()[0].message()).contains("Test GodotGdErrorMonitor 'push_error' reporting")
	else:
		fail("Expect reporting push_error")
