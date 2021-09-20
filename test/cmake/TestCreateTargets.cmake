function(test_create_targets)
    _doxygen_set(OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    _doxygen_set(GENERATE_HTML ON)
    _doxygen_set(GENERATE_LATEX ON)
    #_JSON_set(doxygen.output-latex.generate-latex true)
    _doxygen_set(GENERATE_PDF true)

    #add_custom_target(_test COMMAND "${CMAKE_COMMAND} --version")
    _doxygen_set(INPUT_TARGET main)
    _doxygen_set(TARGET_NAME "doxygen_docs")
    configure_file(cmake/Doxyfile2
            ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile2 @ONLY)
    _doxygen_add_targets(${PROJECT_SOURCE_DIR}/Doxyfile2
            ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile2)
    _doxygen_add_open_targets(doxygen_docs "${CMAKE_CURRENT_BINARY_DIR}")

    if (NOT TARGET doxygen_docs)
        _doxygen_assert_fail("doxygen target `doxygen_docs` was not created")
    endif()
    if (NOT TARGET doxygen_docs.open_html)
        _doxygen_assert_fail("The target `doxygen_docs.open_html` was not created")
    endif()
    if (NOT TARGET doxygen_docs.open_latex)
        _doxygen_assert_fail("The target `doxygen_docs.open_latex` was not created")
    endif()
    if (NOT TARGET doxygen_docs.open_pdf)
        _doxygen_assert_fail("The target `doxygen_docs.open_pdf` was not created")
    endif()
endfunction()

test_create_targets()