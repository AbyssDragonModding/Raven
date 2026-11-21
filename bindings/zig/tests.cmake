# Tests of the idiomatic Zig layer (bindings/zig/src) and its package
# (bindings/zig/build.zig), included at the end of bindings/CMakeLists.txt.
# Kept in a file of its own so that the branch that holds the Zig layer only
# adds one line to the files of Raven, and merges the updates of Raven cleanly.
#
#   binding_zig_wrapper_up_to_date   zig/src/raven.zig is what gen_zig_wrapper.py writes from the headers
#   binding_zig_wrapper              needs zig 0.17: `zig build check`, every declaration compiles (nothing linked)
#   binding_zig_wrapper_test         the same and the shared library: `zig build test` (headless tests, example);
#                                    build.zig puts the folder of the DLL on the PATH: it runs on Windows too

if(Python3_FOUND)
	add_test(NAME binding_zig_wrapper_up_to_date
		COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/bindgen/gen_zig_wrapper.py --check)
endif()

find_program(RAVEN_ZIG zig)
if(RAVEN_ZIG)
	execute_process(COMMAND ${RAVEN_ZIG} version OUTPUT_VARIABLE RAVEN_ZIG_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
	if(RAVEN_ZIG_VERSION VERSION_GREATER_EQUAL 0.17)
		set(RAVEN_ZIG_BUILD ${RAVEN_ZIG} build --cache-dir ${CMAKE_CURRENT_BINARY_DIR}/zig-cache
			--prefix ${CMAKE_CURRENT_BINARY_DIR}/zig-out)
		add_test(NAME binding_zig_wrapper
			COMMAND ${RAVEN_ZIG_BUILD} check
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
		if(RAVEN_BUILD_SHARED)
			add_test(NAME binding_zig_wrapper_test
				COMMAND ${RAVEN_ZIG_BUILD} test "-Dlib-dir=$<TARGET_LINKER_FILE_DIR:raven>" "-Dbin-dir=$<TARGET_FILE_DIR:raven>"
				WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
		endif()
	endif()
endif()
