##############################################################################
# Copyright (c) 2020-2021 Igor Chalenko
# Distributed under the MIT license.
# See accompanying file LICENSE.md or copy at
# https://opensource.org/licenses/MIT
##############################################################################

get_filename_component(_doxygen_dir ${CMAKE_CURRENT_LIST_FILE} PATH)

include(${_doxygen_dir}/Logging.cmake)
include(${_doxygen_dir}/TPA.cmake)
include(${_doxygen_dir}/CMakeTargetGenerator.cmake)
include(${_doxygen_dir}/ProjectFileGenerator.cmake)
include(${_doxygen_dir}/ProjectFunctions.cmake)
include(${_doxygen_dir}/PropertyHandlers.cmake)

##############################################################################
#.rst:
# ---------
# Functions
# ---------
#
# ==================
# doxygen_add_docs
# ==================
#
# .. code-block:: cmake
#
#    doxygen_add_docs([PROJECT_FILE] <name>
#                     [INPUT_TARGET] <name>
#                     [EXAMPLES] <directories>
#                     [INPUTS] <files and directories>
#                     [INSTALL_COMPONENT] <name>
#                     [GENERATE_HTML]
#                     [GENERATE_LATEX]
#                     [GENERATE_PDF]
#                     [GENERATE_XML]
#                     [OUTPUT_DIRECTORY] <directory>
#                     [TARGET_NAME] <name>)
#
# Generates documentation using `doxygen`. Performs the following tasks:
#
# * Generates prepared project file from a project template;
# * Generates requested :ref:`targets<cmake-target-generator-reference-label>`;
# * Adds the generated files to the ``install`` target, if the option
#   :cmake:variable:`DOXYGEN_INSTALL_DOCS` is enabled.
#
# Input options
# *************
#
# **PROJECT_FILE**
#    A project file template. `doxygen-cmake` uses this file as a basis for
#    the actual project file, which is created during `CMake` configuration phase.
#    Refer to the section :ref:`algorithm<algorithm-reference-label>` for
#    a detailed description of the transformations applied to the project
#    template.
#
#    Defaults to ``Doxyfile``, provided by the package.
#
# .. _inputs-reference-label:
#
# **INPUTS**
#    A list of files and directories to be processed by `DoxyPress`; takes
#    priority over `INPUT_TARGET`.
#
# **INPUT_TARGET**
#    If defined, the input sources are taken from the property
#    ``INTERFACE_INCLUDE_DIRECTORIES`` of this target. If
#    :ref:`INPUTS<inputs-reference-label>` are not empty, this parameter
#    is ignored.
#
# **INSTALL_COMPONENT**
#    Specifies component name in the installation command that is added to
#    the `install` target. The default value is ``docs``.
#
# **OUTPUT_DIRECTORY**
#     The base directory for all the generated documentation files.
#     The default is ``doxygen-generated``.
#
# **TARGET_NAME**
#     The name of the `DoxyPress` target. The default is
#     ``${INPUT_TARGET}.doxygen`` if ``INPUT_TARGET`` is supplied, or
#     ``${PROJECT_NAME}.doxygen`` otherwise.
#
# .. _overrides-reference-label:
#
# Property overrides
# ******************
#
# In addition to the parameters accepted by :ref:`doxygen_add_docs`,
# it's also possible to change other configuration properties without changing
# the input project file. The function :cmake:command:`doxygen_add_override`
# serves this purpose. This could be handy if you want to use the default
# project file and need to change some `DoxypressCMake` settings, or you need
# to update a certain property based on some custom logic.
# To do so, call :cmake:command:`doxygen_add_override`: the first argument
# is a JSON path to update, and the second one is the value to put under that
# path. For example, the following command will instruct `DoxyPress` to inline
# source code into the generated documentation:
#
# .. code-block:: cmake
#
#   doxygen_add_override(source.inline-source true)
#
# .. note::
#   The current scope is cleared after each call to :ref:`doxygen_add_docs`.
#   Therefore, if you call this function
#   more than once in the same directory, you need to specify overrides every
#   time. Similarly, it's not possible to specify global overrides for all
#   the sub-projects in a project. If needed, a function could be implemented
#   to wrap a call to :ref:`doxygen_add_docs` together with related
#   overrides.
#
# :ref:`doxygen_add_docs` uses overrides internally to provide
# defaults that are meaningful in the context of `CMake` processing (and in
# general). The following properties are always set to a constant value:
#
# * ``output-html.html-output`` = ``html``
# * ``output-latex.latex-output`` = ``latex``
# * ``output-xml.xml-output`` = ``xml``
#
#    The author sees little value in customizing these since the base output
#    directory is customizable.
#
# * ``project.project-name`` = ``${PROJECT_NAME}``
# * ``project.project-version`` = ``${PROJECT_VERSION}``
# * ``project.project-brief`` = ``${PROJECT_DESCRIPTION}``
#
#    These are specified in `CMakeLists.txt`; one doesn't have to maintain
#    project nomenclature more times than needed.
#
# * ``input.input-recursive`` = ``true``
# * ``input.example-recursive`` = ``true``
#
#   The default template generated by `DoxyPress` sets these to ``false``,
#   mimicking the behavior of `Doxygen`. The author believes the value of
#   ``true`` is more appropriate, given the number of ``exclude`` options that
#   allow achieving the same result. One has to be able to freely
#   expand/refactor the existing source tree without worrying about breaking
#   documentation.
#
# * ``dot.have-dot``
# * ``dot.dot-path``
# * ``dot.dia-path``
#
#   These properties depend on the local environment and thus should not be
#   hard-coded.
#
# * ``output-latex.latex-cmd-name`` = ``${PDFLATEX_COMPILER}``
# * ``output-latex.make-index-cmd-name`` = ``${MAKEINDEX_COMPILER}``
#
#   These properties depend on the local environment and thus should not be
#   hard-coded.
#
# * ``output-latex.latex-pdf`` = ``true``
#
#   If `pdflatex` is installed, it will be used to get "a better quality PDF",
#   as stated in `DoxyPress` documentation (and originally in `Doxygen`'s).
#
# * ``output-latex.latex-batch-mode`` = ``true``
#
#   LaTex batch mode enables non-interactive processing, which is exactly what
#   the package does.
#
# * ``output-latex.latex-hyper-pdf`` = ``true``
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
#   ``output-latex.latex-cmd-name`` and ``output-latex.make-index-cmd-name`` are
#   unset.
#
# * ``messages.warn-format``
#
#   This is configured separately for MS Visual Studio; other build tools
#   use a default value.
#
# .. _algorithm-reference-label:
#
# Algorithm
# *********
#
# * 1. The input JSON configuration is parsed into a flat list of variables as
#   described in the documentation for ``sbeParseJson`` from json-cmake_.
# * 2. Some of these variables get a new value. The set of JSON properties
#   to update is defined by :cmake:command:`_doxygen_params_init_properties`.
#   Each property is assigned a set of handlers, described in the documentation
#   for :cmake:command:`_doxygen_property_add`. Then, the following logic
#   is applied for each individual property:
#
#   * the `current value` is assigned an empty string;
#   * the input argument, if it was specified, becomes the new current value;
#   * ``SETTER`` is invoked if the current property value is empty;
#   * ``UPDATER`` is invoked if the current property value is NOT empty;
#   * the current value is set to the value of ``DEFAULT`` if the current
#     property value is still empty.
# * 3. Property overrides are applied.
# * 4. The list of variables is re-assembled back into a new JSON document,
#   which is then written to a file that becomes the final DoxyPress
#   configuration.
#
# There are four sources of property values that may contribute to the final,
# processed project file:
#
# * input arguments provided to :ref:`doxygen_add_docs<Functions>`;
# * defaults set by `doxygen-cmake`;
# * input project file;
# * CMake variables that override the values in the project file.
#
# The order of evaluation is:
#
# ``inputs`` -> ``overrides`` -> ``project file`` -> ``defaults``
#
# That is, once a value is set upstream, downstream sources are ignored (with
# an exception for merging):
#
# * If an input value is given for a property, the override of the corresponding
#   property is ignored. The corresponding value in the input project file is
#   ignored as well unless it is an array; in this case, the input value is
#   appended to the array in the project file.
# * If an input parameter is empty, but there is an override for it,
#   the corresponding value in the input project file is ignored.
# * If an input parameter is empty and there's no override for the corresponding
#   property, the value in the project remains unchanged.
# * If the first three sources didn't provide a non-empty value, the property
#   receives a default value.
#
# .. _json-cmake: https://github.com/sbellus/json-cmake
##############################################################################
function(doxygen_add_docs_2)
    TPA_set("add.docs.args" "${ARGN}")
    # initialize parameter/property descriptions
    _doxygen_params_init()
    # parse input arguments
    _doxygen_inputs_parse(${ARGN})

    # get the project file name
    _doxygen_get(PROJECT_FILE _project_file)

    _doxygen_output_project_file_name(${_project_file} _updated_project_file)

    _doxygen_add_targets("${_project_file}" "${_updated_project_file}")

    if (DOXYGEN_INSTALL_DOCS)
        # install generated files
        _doxygen_install_docs()
    endif ()

    # clear up the TPA scope created by this function
    TPA_clear_scope()
endfunction()

function(doxygen_add_docs_new)
    TPA_set("add.docs.args" "${ARGN}")
    # parse input arguments
    _doxygen_parse_inputs(${ARGN})

    TPA_get(doxygen.updatable.properties _input_properties)
    foreach(_property ${_input_properties})
        _doxygen_get(${_property} _value)
        message(STATUS "obtained ${_property} = ${_value}")
    endforeach()

    # get the project file name
    #_doxygen_get(PROJECT_FILE _project_file)

    #_doxygen_output_project_file_name(${_project_file} _updated_project_file)

    #_doxygen_add_targets("${_project_file}" "${_updated_project_file}")

    _doxygen_create_generate_project_target()
    _doxygen_create_generate_docs_target()
    #_doxygen_create_open_targets()

    #if (DOXYGEN_INSTALL_DOCS)
        # install generated files
    #    _doxygen_create_install_targets()
    #endif ()

    # clear up the TPA scope created by this function
    TPA_clear_scope()
endfunction()

function(doxygen_prepare_doxyfile)
    # initialize parameter/property descriptions
    _doxygen_params_init()
    # parse input arguments
    _doxygen_parse_inputs(${ARGN})

    # get the project file name
    _doxygen_get(PROJECT_FILE _project_file)
    message(STATUS "PROJECT_FILE = ${_project_file}")
    # update project file
    _doxygen_update_path(PROJECT_FILE ${ARGN})

    _doxygen_project_update(_updated_project_file "${_project_file}" ${ARGN})
    # clear up the TPA scope created by this function
    TPA_clear_scope()
endfunction()

function(doxygen_add_docs)
    TPA_set("add.docs.args" "${ARGN}")
    # initialize input parameters
    _doxygen_input_params_init()
    # parse input arguments
    _doxygen_inputs_parse(${ARGN})

    # get the project file name
    _doxygen_get(PROJECT_FILE _project_file)

    _doxygen_output_project_file_name(${_project_file} _updated_project_file)

    _doxygen_add_generate_target("${_project_file}" "${_updated_project_file}")

    if (DOXYGEN_INSTALL_DOCS)
        # install generated files
        _doxygen_add_install_target()
    endif ()

    # clear up the TPA scope created by this function
    TPA_clear_scope()
endfunction()

##############################################################################
#.rst:
#
# ======================
# doxygen_add_override
# ======================
#
# .. code-block:: cmake
#
#   doxygen_add_override(_path _value)
#
# Creates an :ref:`override<overrides-reference-label>` with the given value.
##############################################################################
function(doxygen_add_override _path _type _value)
    _doxygen_property_add(${_path} ${_type} DEFAULT "${_value}" OVERWRITE)
endfunction()

##############################################################################
#.rst:
# -------
# Options
# -------
#
# .. cmake:variable:: DOXYGEN_INSTALL_DOCS
#
# Specifies whether the files generated by `Doxypress` should be installed by
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
# by `Doxypress`.
#
##############################################################################
option(DOXYGEN_ADD_OPEN_TARGETS
        "Add open targets for the generated documentation" ON)

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYGEN_PROMOTE_WARNINGS
#
# Specifies what message level ``_doxygen_log(WARN text)`` should use.
#
# .. code-block:: cmake
#
#    # DOXYGEN_PROMOTE_WARNINGS = ON
#    _doxygen_log(WARN text) # equivalent to message(WARNING text)
#    # DOXYGEN_PROMOTE_WARNINGS = OFF
#    _doxygen_log(WARN text) # equivalent to message(STATUS text)
#
##############################################################################
option(DOXYGEN_PROMOTE_WARNINGS "Promote log warnings to CMake warnings" OFF)

##############################################################################
#.rst:
# ---------
# Variables
# ---------
#
##############################################################################

##############################################################################
#.rst:
#
# .. cmake:variable:: DOXYGEN_LOG_LEVEL
#
# Controls output produced by `_doxygen_log`. Set to ``INFO`` by default.
#
# .. code-block:: cmake
#
#    # DOXYGEN_LOG_LEVEL = DEBUG
#    _doxygen_log(DEBUG text) # equivalent to message(STATUS text)
#    _doxygen_log(INFO text) # equivalent to message(STATUS text)
#    _doxygen_log(WARN text) # equivalent to message(STATUS text)
#    # DOXYGEN_LOG_LEVEL = INFO
#    _doxygen_log(DEBUG text) # does nothing
#    _doxygen_log(INFO text) # equivalent to message(STATUS text)
#    _doxygen_log(WARN text) # equivalent to message(STATUS text)
#    # DOXYGEN_LOG_LEVEL = WARN
#    _doxygen_log(DEBUG text) # does nothing
#    _doxygen_log(INFO text) # does nothing
#    _doxygen_log(WARN text) # equivalent to message([STATUS|WARNING] text)
##############################################################################
set(DOXYGEN_LOG_LEVEL WARN CACHE STRING "doxygen-cmake logging level")
