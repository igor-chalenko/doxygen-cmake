##############################################################################
# Copyright (c) 2020-2021 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

get_filename_component(_doxygen_dir ${CMAKE_CURRENT_LIST_FILE} PATH)

_doxygen_find_package(cmake-utilities REQUIRED)

parameter_to_function_prefix(doxygen global_get global_set
        global_unset global_append global_clear global_index)

include(${_doxygen_dir}/project-functions.cmake)
include(${_doxygen_dir}/cmake-target-generators.cmake)
include(${_doxygen_dir}/property-handlers.cmake)

##############################################################################
#.rst:
# ---------
# Functions
# ---------
#
# ===================
# add_doxygen_targets
# ===================
#
# .. _add_doxygen_targets:
#
# .. code-block:: cmake
#
#    add_doxygen_targets(
#                     [PROJECT_FILE] <name>
#                     [DOCS_TARGET] <name>
#                     [INPUT_TARGET] <name>
#                     [INSTALL_COMPONENT] <name>
#                     [GENERATE_PDF]
#                     [<PROPERTY> <value>]...)
#
# Generates documentation using `doxygen`. Performs the following tasks:
#
# * Generates prepared project file from a given project template; generates
#   a default template if non provided.
# * Generates requested :ref:`targets<targets-reference-label>`;
# * Adds the generated files to the ``install`` target, if the option
#   :cmake:variable:`DOXYGEN_INSTALL_DOCS` is enabled.
#
# Input parameters
# ****************
#
# **DOCS_TARGET**
#     A name of the `Doxygen` target. The default value is
#     ``${INPUT_TARGET}.doxygen`` if ``INPUT_TARGET`` is supplied, or
#     ``${PROJECT_NAME}.doxygen`` otherwise.
#
# .. _input-reference-label:
#
# **INPUT**
#    A list of files and directories to be processed by `Doxygen`; takes
#    priority over `INPUT_TARGET`.
#
# **INPUT_TARGET**
#    If defined, the input files are taken from the property
#    ``INCLUDE_DIRECTORIES`` or ``INTERFACE_INCLUDE_DIRECTORIES`` of this
#    target. If :ref:`INPUT<input-reference-label>` is not empty, this
#    parameter is ignored.
#
# **INSTALL_COMPONENT**
#    Specifies component name in the installation command that is added to
#    the `install` target. The default value is ``docs``.
#
# **PROJECT_FILE**
#    A project file template. `doxygen-cmake` uses this file as a basis for
#    the actual project file, which is created during `CMake` configuration phase.
#    Refer to the section :ref:`algorithm<algorithm-reference-label>` for
#    a detailed description of the transformations applied to the project
#    template.
#
#    Defaults to ``Doxyfile.in``, generated by the package.
#
# **WORKING_DIRECTORY**
#    Doxygen working directory. Defaults to ``CMAKE_CURRENT_SOURCE_DIR``.
#
# Special parameters
# ******************
#
# In addition to the aforementioned parameters, :ref:`add_doxygen_targets<add_doxygen_targets>`,
# also accepts other configuration properties. For example:
#
# .. code-block:: cmake
#
#   add_doxygen_targets(... INLINE_SOURCES YES)
#
# Special logic applies to some of the properties, as deemed necessary in
# the `CMake` context, when certain assumptions help to separate host-specific
# and host-independent configuration properties, and lift the task of handling
# the host-specific ones off the user.
#
# The following properties are always set to a constant value:
#
# * ``HTML_OUTPUT`` = ``html``
# * ``LATEX_OUTPUT`` = ``latex``
# * ``XML_OUTPUT`` = ``xml``
#
#   The author sees little value in customizing these since the base output
#   directory is customizable.
#
# * ``PROJECT_NAME`` = ``${PROJECT_NAME}``
# * ``PROJECT_VERSION`` = ``${PROJECT_VERSION}``
# * ``PROJECT_BRIEF`` = ``${PROJECT_DESCRIPTION}``
#
#   These can be specified in `CMakeLists.txt`; one doesn't have to maintain
#   project nomenclature more times than needed.
#
# * ``INPUT_RECURSIVE`` = ``true``
# * ``EXAMPLE_RECURSIVE`` = ``true``
#
#   The default template generated by `Doxygen` sets these to ``NO``.The author
#   believes the value of ``YES``  cis more appropriate, given the number of
#   ``exclude`` options that allow achieving the same result. One has to be able
#   to freely expand/refactor the existing source tree without worrying about
#   breaking the documentation.
#
# * ``HAVE_DOT``
# * ``DOT_PATH``
# * ``DIA_PATH``
#
#   These properties depend on the local environment and thus should not be
#   hard-coded.
#
# * ``LATEX_CMD_NAME`` = ``${PDFLATEX_COMPILER}``
# * ``MAKE_INDEX_CMD_NAME`` = ``${MAKEINDEX_COMPILER}``
#
#   These properties depend on the local environment and thus should not be
#   hard-coded.
#
# * ``USE_PDFLATEX`` = ``YES``
#
#   Most `LaTex` distributions have `pdflatex`. If `pdflatex` is installed,
#   it will be used to get "a better quality PDF", as stated in `Doxygen`
#   documentation.
#
# * ``LATEX_BATCHMODE`` = ``YES``
#
#   LaTex batch mode enables non-interactive processing, which is exactly what
#   the package does.
#
# * ``PDF_HYPERLINKS`` = ``YES``
#
#   Hyperlink generation requires running ``pdflatex`` several times, but these
#   days it's not that expensive, while the value of hyperlinks is great.
#
# .. note::
#   If `.tex` generation was requested, but LaTex installation was not found
#   after the call to
#
#   .. code-block:: cmake
#
#     find_package(LATEX)
#
#   then the `.tex` generation is disabled and the properties
#   ``LATEX_CMD_NAME`` and ``MAKEINDEX_CMD_NAME`` are left untouched.
#   todo this is not true
#
# * ``WARN_FORMAT``
#
#   This property depends on the local environment and thus should not be
#   hard-coded.
#
#  The following properties in the input project file may be updated:
#
# * ``INPUT``
#
#  If the respective input argument was given, every input path will be
#  converted to an absolute one and stored into the final project file.
#  If ``INPUT`` was not specified, but ``INPUT_TARGET`` was, the target's
#  include directories will be searched recursively for any matching
#  files (as defined by `FILE_PATTERNS`). Again, every resulting file
#  will have an absolute path.
#
# * ``EXAMPLE_PATH``
#
#  If one or more relative path is specified, they will be converted to
#  the absolute ones in accordance with the build topology. If the project
#  value is empty, the package will try to search for the directories
#  ``example`` and ``examples`` in the project directory, and substitute
#  one of those if found (``examples`` will not be added if ``example``
#  already was). Otherwise, left empty.
#
# * ``OUTPUT_DIRECTORY``
#
#  The base directory for all the generated documentation files.
#  The default is ``${CMAKE_CURRENT_BINARY_DIR}/doxygen-generated``.
#
# .. _targets-reference-label:
#
# Targets
# *******
#
# This module implements creation of the following targets:
#
# * ``${TARGET_NAME}`` to run `Doxygen`;
# * ``${TARGET_NAME}.open_html``:
#
#   .. code-block:: bash
#
#      ${DOXYGEN_LAUNCHER_COMMAND} ${OUTPUT_DIRECTORY}/html/index.html
#
#   This target is created unless HTML generation was disabled.
#
#   * ``${TARGET_NAME}.latex``:
#
#   .. code-block:: bash
#
#      ${DOXYGEN_LAUNCHER_COMMAND} ${OUTPUT_DIRECTORY}/latex/refman.tex
#
#   This target is created if LaTex generation was enabled.
#
#   * ``${TARGET_NAME}.pdf``:
#
#   .. code-block:: bash
#
#      ${DOXYGEN_LAUNCHER_COMMAND} ${OUTPUT_DIRECTORY}/pdf/refman.pdf
#
#   This target is created if PDF generation was enabled.
#
# In addition to the above, ``doxygen-cmake`` adds documentation files
# to the ``install`` target, if ``DOXYGEN_INSTALL_DOCS`` is enabled.
# The set files to install is the same as the set of the generated files.
#
# Logging
# *******
#
# The package's log verbosity is controlled by several log categories,
# each set to `WARN` initially.
#
# * ``log_level(doxygen <level>)``
#
#  At the ``INFO`` level, will log target creation and file operations.
#  At the ``DEBUG`` level, will also provide details about the targets created.
#  At the ``TRACE`` level, will also log the transformations applied to
#  the input project file.
#
# * ``log_level(doxygen.list_inputs <level>)``
#
#  At the ``DEBUG`` level, will log the details about the input collection
#  process.
#
# * ``log_level(doxygen.updaters <level>)``
#
#  At the ``DEBUG`` level, will log the details about the operations setters
#  and updaters perform.
#
# .. _algorithm-reference-label:
#
# Algorithm
# *********
#
# 1. Input arguments are parsed to obtain the input project file name.
# 2. The input project file is parsed into a list of properties
#    ([`key`, `value`] pairs).
# 3. Some of these properties may get a new value, as detailed below:
#
#   * The `current value` is assigned an empty string.
#   * The input argument, if it was specified, becomes the new current value;
#   * otherwise, the current value is set to its default value (if any).
#   * ``SETTER`` is invoked if the current property value is still empty.
#   * ``UPDATER`` is invoked unconditionally.
#
# 4. The list of properties is re-assembled back into a new project file,
#    which is then written to a file that becomes the final Doxygen
#    configuration.
#
# There are three sources of property values that may contribute to the final,
# processed project file:
#
# * input arguments provided to :ref:`add_doxygen_targets<add_doxygen_targets>`;
# * defaults set by `doxygen-cmake`;
# * input project file.
#
# The order of evaluation is:
#
# ``inputs`` -> ``project file`` -> ``defaults`` -> ``setters``/``updaters``
#
# That is, once a value is set upstream, downstream sources are ignored.
##############################################################################
function(add_doxygen_targets)
    # parse input arguments
    _doxygen_parse_inputs(${ARGN})

    # get the project file name
    #_doxygen_project_update(_contents "${PROJECT_FILE}")
    _doxygen_load_project("${PROJECT_FILE}" _properties)

    _doxygen_update_properties(_properties ${ARGN})

    # create name for the processed project file
    _doxygen_output_project_file_name(
            ${PROJECT_FILE}
            _output_project_file_name)

    _doxygen_collect_dependencies(_dependencies)
    log_debug(doxygen "Collected project dependencies: ${_dependencies}")

    _doxygen_create_generate_docs_target(
            "${WORKING_DIRECTORY}"
            "${PROJECT_FILE}"
            "${OUTPUT_DIRECTORY}"
            "${DOCS_TARGET}"
            ${GENERATE_PDF} ${_dependencies})
    if (DOXYGEN_OPEN_TARGETS)
        _doxygen_create_open_targets(
                "${PROJECT_FILE}"
                "${OUTPUT_DIRECTORY}"
                "${DOCS_TARGET}"
                ${GENERATE_HTML}
                ${GENERATE_LATEX}
                ${GENERATE_PDF})
    endif()

    if (DOXYGEN_INSTALL_DOCS)
        # install generated files
        _doxygen_create_install_targets()
    endif ()

    # save processed project file
    _doxygen_save_project("${_output_project_file_name}" ${_properties})
endfunction()

##############################################################################
#.rst:
# -------
# Options
# -------
#
# .. cmake:variable:: DOXYGEN_INSTALL_DOCS
#
# Specifies whether the files generated by `Doxygen` should be installed by
#
# .. code-block:: bash
#
#    make install INSTALL_COMPONENT
#
##############################################################################
option(DOXYGEN_INSTALL_DOCS "Install generated documentation" OFF)

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYGEN_ADD_OPEN_TARGETS
#
# Specifies whether open targets should be created for the files generated
# by `Doxygen`.
#
##############################################################################
option(DOXYGEN_OPEN_TARGETS
        "Add open targets for the generated documentation" ON)

