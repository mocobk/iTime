#!/usr/bin/env python3
"""Generate itime.xcodeproj from the source directory structure."""
import os
import hashlib
import json

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(PROJECT_DIR, "itime")
TEST_DIR = os.path.join(PROJECT_DIR, "itimeTests")

# Read version from VERSION file (single source of truth)
VERSION_FILE = os.path.join(PROJECT_DIR, "VERSION")
try:
    with open(VERSION_FILE, "r") as f:
        APP_VERSION = f.read().strip()
except FileNotFoundError:
    APP_VERSION = "1.0.0"

def make_id(name, salt=""):
    """Generate a deterministic 24-char hex ID from a name."""
    h = hashlib.md5(f"{name}{salt}".encode()).hexdigest().upper()
    return h[:24]

def find_swift_files(directory):
    """Recursively find all .swift files."""
    files = []
    for root, dirs, filenames in os.walk(directory):
        for f in sorted(filenames):
            if f.endswith(".swift"):
                files.append(os.path.join(root, f))
    return files

# Collect source files
source_files = find_swift_files(SRC_DIR)
test_files = find_swift_files(TEST_DIR)

# Generate IDs
project_id = make_id("project")
main_group_id = make_id("mainGroup")
source_group_id = make_id("sourceGroup")
test_group_id = make_id("testGroup")
app_target_id = make_id("appTarget")
test_target_id = make_id("testTarget")
product_ref_id = make_id("product")
test_product_ref_id = make_id("testProduct")

# Build configuration IDs
project_config_list_id = make_id("projectConfigList")
app_config_list_id = make_id("appConfigList")
test_config_list_id = make_id("testConfigList")
project_debug_id = make_id("projectDebug")
project_release_id = make_id("projectRelease")
app_debug_id = make_id("appDebug")
app_release_id = make_id("appRelease")
test_debug_id = make_id("testDebug")
test_release_id = make_id("testRelease")

# Build phase IDs
sources_phase_id = make_id("sourcesPhase")
frameworks_phase_id = make_id("frameworksPhase")
resources_phase_id = make_id("resourcesPhase")
test_sources_phase_id = make_id("testSourcesPhase")
test_frameworks_phase_id = make_id("testFrameworksPhase")

# Resources
assets_ref_id = make_id("Assets.xcassets")
assets_build_id = make_id("Assets.xcassets", "build")
entitlements_ref_id = make_id("entitlements")
infoplist_ref_id = make_id("Info.plist")

# Target dependency
target_dep_id = make_id("targetDependency")
embed_phase_id = make_id("embedPhase")

def rel_path(full_path):
    return os.path.relpath(full_path, PROJECT_DIR)

def make_file_ref(fpath):
    name = os.path.basename(fpath)
    rp = rel_path(fpath)
    return make_id(rp, "ref")

def make_build_file(fpath):
    rp = rel_path(fpath)
    return make_id(rp, "build")

# Build PBXFileReference entries for source files
file_refs = {}
for f in source_files + test_files:
    rp = rel_path(f)
    file_refs[rp] = make_file_ref(f)

# Build PBXBuildFile entries
build_files = {}
for f in source_files:
    rp = rel_path(f)
    build_files[rp] = make_build_file(f)

test_build_files = {}
for f in test_files:
    rp = rel_path(f)
    test_build_files[rp] = make_build_file(f)

# Create group hierarchy
def build_groups(base_dir, parent_path=""):
    groups = {}
    children_files = []
    children_groups = []

    items = sorted(os.listdir(base_dir))
    for item in items:
        full = os.path.join(base_dir, item)
        if os.path.isdir(full) and not item.startswith("."):
            group_id = make_id(os.path.relpath(full, PROJECT_DIR), "group")
            sub = build_groups(full, os.path.relpath(full, PROJECT_DIR))
            groups[item] = {"id": group_id, "path": item, "children": sub}
            children_groups.append(item)
        elif item.endswith(".swift"):
            rp = os.path.relpath(full, PROJECT_DIR)
            children_files.append(rp)

    return {"_files": children_files, "_groups": children_groups, **{k: v for k, v in groups.items() if k not in ("_files", "_groups")}}

src_tree = build_groups(SRC_DIR)

def write_group_section(group_name, group_data, parent_path=""):
    sections = []
    gid = make_id(group_name, "group") if parent_path else source_group_id

    file_children = []
    for rp in group_data.get("_files", []):
        file_children.append(f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */,")

    group_children = []
    for gname in group_data.get("_groups", []):
        gdata = group_data[gname]
        group_children.append(f"\t\t\t\t{gdata['id']} /* {gname} */,")
        sub_sections = write_group_section(gname, gdata, gname)
        sections.extend(sub_sections)

    all_children = group_children + file_children

    section = f"""\t\t{gid} /* {group_name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{"".join(all_children)}
\t\t\t);
\t\t\tpath = {group_name};
\t\t\tsourceTree = "<group>";
\t\t}};
"""
    sections.insert(0, section)
    return sections

# Generate the pbxproj content
lines = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {")
lines.append("\t};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")
lines.append("")

# PBXBuildFile
lines.append("/* Begin PBXBuildFile section */")
for rp, bid in build_files.items():
    fname = os.path.basename(rp)
    fid = file_refs[rp]
    lines.append(f"\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */;}};")
for rp, bid in test_build_files.items():
    fname = os.path.basename(rp)
    fid = file_refs[rp]
    lines.append(f"\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */;}};")
lines.append(f"\t\t{assets_build_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref_id} /* Assets.xcassets */;}};")
lines.append("/* End PBXBuildFile section */")
lines.append("")

# PBXFileReference
lines.append("/* Begin PBXFileReference section */")
for rp, fid in file_refs.items():
    fname = os.path.basename(rp)
    lines.append(f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = "<group>";}};')
lines.append(f'\t\t{assets_ref_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";}};')
lines.append(f'\t\t{entitlements_ref_id} /* itime.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = itime.entitlements; sourceTree = "<group>";}};')
lines.append(f'\t\t{product_ref_id} /* itime.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = itime.app; sourceTree = BUILT_PRODUCTS_DIR;}};')
lines.append(f'\t\t{test_product_ref_id} /* itimeTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = itimeTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;}};')
lines.append("/* End PBXFileReference section */")
lines.append("")

# PBXFrameworksBuildPhase
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.append(f"""\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")
lines.append(f"""\t\t{test_frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")
lines.append("/* End PBXFrameworksBuildPhase section */")
lines.append("")

# PBXGroup
lines.append("/* Begin PBXGroup section */")

# Root group
src_build_files_list = "\n".join([f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */," for rp in sorted(file_refs.keys()) if rp.startswith("itime/")])
test_files_list = "\n".join([f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */," for rp in sorted(file_refs.keys()) if rp.startswith("itimeTests/")])

# Build sub-groups for itime source
sub_groups_text = ""
src_subdirs = ["App", "Models", "Engine", "Services", "UI", "Utilities"]
sub_group_ids = []
for subdir in src_subdirs:
    sgid = make_id(f"itime/{subdir}", "group")
    sub_group_ids.append(sgid)
    sub_files = sorted([rp for rp in file_refs.keys() if rp.startswith(f"itime/{subdir}/")])
    children = "\n".join([f"\t\t\t\t{file_refs[rp]} /* {os.path.basename(rp)} */," for rp in sub_files])
    sub_groups_text += f"""\t\t{sgid} /* {subdir} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}
\t\t\t);
\t\t\tpath = {subdir};
\t\t\tsourceTree = "<group>";
\t\t}};
"""

# Resources group
resources_group_id = make_id("Resources", "group")
sub_groups_text += f"""\t\t{resources_group_id} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{assets_ref_id} /* Assets.xcassets */,
\t\t\t\t{entitlements_ref_id} /* itime.entitlements */,
\t\t\t);
\t\t\tpath = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

lines.append(f"""\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{source_group_id} /* itime */,
\t\t\t\t{test_group_id} /* itimeTests */,
\t\t\t\t{make_id("Products", "group")} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};""")

lines.append(f"""\t\t{make_id("Products", "group")} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_ref_id} /* itime.app */,
\t\t\t\t{test_product_ref_id} /* itimeTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};""")

lines.append(f"""\t\t{source_group_id} /* itime */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join([f'\t\t\t\t{sgid} /* {subdir} */,' for sgid, subdir in zip(sub_group_ids, src_subdirs)])}
\t\t\t\t{resources_group_id} /* Resources */,
\t\t\t);
\t\t\tpath = itime;
\t\t\tsourceTree = "<group>";
\t\t}};""")

lines.append(sub_groups_text)

lines.append(f"""\t\t{test_group_id} /* itimeTests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{test_files_list}
\t\t\t);
\t\t\tpath = itimeTests;
\t\t\tsourceTree = "<group>";
\t\t}};""")

lines.append("/* End PBXGroup section */")
lines.append("")

# PBXNativeTarget
src_build_file_entries = "\n".join([f"\t\t\t\t{bid} /* {os.path.basename(rp)} in Sources */," for rp, bid in sorted(build_files.items())])
test_build_file_entries = "\n".join([f"\t\t\t\t{bid} /* {os.path.basename(rp)} in Sources */," for rp, bid in sorted(test_build_files.items())])

lines.append("/* Begin PBXNativeTarget section */")
lines.append(f"""\t\t{app_target_id} /* itime */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {app_config_list_id} /* Build configuration list for PBXNativeTarget "itime" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = itime;
\t\t\tproductName = itime;
\t\t\tproductReference = {product_ref_id} /* itime.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};""")

lines.append(f"""\t\t{test_target_id} /* itimeTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {test_config_list_id} /* Build configuration list for PBXNativeTarget "itimeTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{test_sources_phase_id} /* Sources */,
\t\t\t\t{test_frameworks_phase_id} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{target_dep_id} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = itimeTests;
\t\t\tproductName = itimeTests;
\t\t\tproductReference = {test_product_ref_id} /* itimeTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};""")
lines.append("/* End PBXNativeTarget section */")
lines.append("")

# PBXProject
lines.append("/* Begin PBXProject section */")
lines.append(f"""\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tbuildConfigurationList = {project_config_list_id} /* Build configuration list for PBXProject "itime" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {make_id("Products", "group")} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target_id} /* itime */,
\t\t\t\t{test_target_id} /* itimeTests */,
\t\t\t);
\t\t}};""")
lines.append("/* End PBXProject section */")
lines.append("")

# PBXResourcesBuildPhase
lines.append("/* Begin PBXResourcesBuildPhase section */")
lines.append(f"""\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{assets_build_id} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")
lines.append("/* End PBXResourcesBuildPhase section */")
lines.append("")

# PBXSourcesBuildPhase
lines.append("/* Begin PBXSourcesBuildPhase section */")
lines.append(f"""\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{src_build_file_entries}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")

lines.append(f"""\t\t{test_sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{test_build_file_entries}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};""")
lines.append("/* End PBXSourcesBuildPhase section */")
lines.append("")

# PBXTargetDependency
lines.append("/* Begin PBXTargetDependency section */")
lines.append(f"""\t\t{target_dep_id} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {app_target_id} /* itime */;
\t\t\ttargetProxy = {make_id("targetProxy")} /* PBXContainerItemProxy */;
\t\t}};""")
lines.append("/* End PBXTargetDependency section */")
lines.append("")

# PBXContainerItemProxy
lines.append("/* Begin PBXContainerItemProxy section */")
lines.append(f"""\t\t{make_id("targetProxy")} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {project_id} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {app_target_id};
\t\t\tremoteInfo = itime;
\t\t}};""")
lines.append("/* End PBXContainerItemProxy section */")
lines.append("")

# XCBuildConfiguration
lines.append("/* Begin XCBuildConfiguration section */")

# Project Debug
lines.append(f"""\t\t{project_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")

# Project Release
lines.append(f"""\t\t{project_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")

# App Debug
lines.append(f"""\t\t{app_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = itime/Resources/itime.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = itime/Resources/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = iTime;
\t\t\t\tINFOPLIST_KEY_LSUIElement = YES;
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = {APP_VERSION};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.itime.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")

# App Release
lines.append(f"""\t\t{app_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = itime/Resources/itime.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = itime/Resources/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = iTime;
\t\t\t\tINFOPLIST_KEY_LSUIElement = YES;
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = {APP_VERSION};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.itime.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")

# Test Debug
lines.append(f"""\t\t{test_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.itime.app.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/itime.app/Contents/MacOS/itime";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};""")

# Test Release
lines.append(f"""\t\t{test_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.itime.app.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/itime.app/Contents/MacOS/itime";
\t\t\t}};
\t\t\tname = Release;
\t\t}};""")

lines.append("/* End XCBuildConfiguration section */")
lines.append("")

# XCConfigurationList
lines.append("/* Begin XCConfigurationList section */")
lines.append(f"""\t\t{project_config_list_id} /* Build configuration list for PBXProject "itime" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{project_debug_id} /* Debug */,
\t\t\t\t{project_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")

lines.append(f"""\t\t{app_config_list_id} /* Build configuration list for PBXNativeTarget "itime" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{app_debug_id} /* Debug */,
\t\t\t\t{app_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")

lines.append(f"""\t\t{test_config_list_id} /* Build configuration list for PBXNativeTarget "itimeTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{test_debug_id} /* Debug */,
\t\t\t\t{test_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};""")

lines.append("/* End XCConfigurationList section */")

lines.append("\t};")
lines.append(f"\trootObject = {project_id} /* Project object */;")
lines.append("}")

# Write the file
xcodeproj_dir = os.path.join(PROJECT_DIR, "itime.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)
pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
with open(pbxproj_path, "w") as f:
    f.write("\n".join(lines))

print(f"Generated {pbxproj_path}")
print(f"  Source files: {len(source_files)}")
print(f"  Test files: {len(test_files)}")

# Also generate xcscheme
scheme_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)

scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target_id}"
               BuildableName = "itime.app"
               BlueprintName = "itime"
               ReferencedContainer = "container:itime.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target_id}"
               BuildableName = "itimeTests.xctest"
               BlueprintName = "itimeTests"
               ReferencedContainer = "container:itime.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "itime.app"
            BlueprintName = "itime"
            ReferencedContainer = "container:itime.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "itime.app"
            BlueprintName = "itime"
            ReferencedContainer = "container:itime.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

scheme_path = os.path.join(scheme_dir, "itime.xcscheme")
with open(scheme_path, "w") as f:
    f.write(scheme_content)
print(f"Generated {scheme_path}")
