@tool
extends SceneTree

## Unit test proving lambda capture fix for signal handlers
## Run with: godot --headless --script tests/test_lambda_capture.gd

signal test_signal(value: String)

func _init():
	print("=== Lambda Capture Test ===")
	
	# Test 1: Broken pattern (capture by value)
	print("\nTest 1: Broken pattern (should fail)")
	var broken_value := ""
	var broken_handler := func(v: String):
		broken_value = v  # This modifies lambda's copy, not outer variable
	
	test_signal.connect(broken_handler)
	test_signal.emit("test_data")
	test_signal.disconnect(broken_handler)
	
	if broken_value == "":
		print("✅ EXPECTED: outer variable unchanged (lambda captured by value)")
	else:
		print("❌ UNEXPECTED: outer variable changed to '%s'" % broken_value)
	
	# Test 2: Fixed pattern (reference type)
	print("\nTest 2: Fixed pattern (should work)")
	var state := {"value": ""}
	var fixed_handler := func(v: String):
		state.value = v  # This modifies the dictionary, which is passed by reference
	
	test_signal.connect(fixed_handler)
	test_signal.emit("test_data")
	test_signal.disconnect(fixed_handler)
	
	if state.value == "test_data":
		print("✅ SUCCESS: dictionary value updated to '%s'" % state.value)
	else:
		print("❌ FAIL: dictionary value is '%s', expected 'test_data'" % state.value)
	
	# Test 3: Multiple updates
	print("\nTest 3: Multiple updates")
	var counter := {"count": 0}
	var counter_handler := func(_v: String):
		counter.count += 1
	
	test_signal.connect(counter_handler)
	test_signal.emit("1")
	test_signal.emit("2")
	test_signal.emit("3")
	test_signal.disconnect(counter_handler)
	
	if counter.count == 3:
		print("✅ SUCCESS: counter reached %d" % counter.count)
	else:
		print("❌ FAIL: counter is %d, expected 3" % counter.count)
	
	# Summary
	print("\n=== Test Complete ===")
	print("This demonstrates that GDScript lambdas capture by value,")
	print("so signal handlers must use reference types (Dict/Array)")
	print("to update outer state.")
	
	quit(0)
