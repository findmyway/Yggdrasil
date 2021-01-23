# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_version = v"1.5.3"

name = "OpenSpiel"
version = v"0.2.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/deepmind/open_spiel/archive/v0.2.0.tar.gz", "8df457852fa6446a7d1f9a60acb26cae29cdba8377dc1b01d0374a02d4764f18"),
    ArchiveSource("https://github.com/findmyway/dds/archive/v0.1.0.tar.gz", "81070b8e96779b5b2303185642753013aa874bffbd58b9cc599204aee064292d"),
    ArchiveSource("https://github.com/findmyway/abseil-cpp/archive/v0.1.0.tar.gz", "7b612c1fed278250b5d1a4e29ddb410145b26a0e7c781c1ca4ac03d092179202"),
    ArchiveSource("https://github.com/findmyway/hanabi-learning-environment/archive/v0.1.0.tar.gz", "6126936fd13a95f8cadeacaa69dfb38a960eaf3bd588aacc8893a6e07e4791a3"),
    ArchiveSource("https://github.com/findmyway/project_acpc_server/archive/v0.1.0.tar.gz", "e29f969dd62ba354b7019cae3f7f1dbfbd9a744687ea4a8f7494c2bb1ee87382"),
]

# Bash recipe for building across all platforms
script = raw"""

mv open_spiel-0.2.0 open_spiel
mv abseil-cpp-0.1.0/ open_spiel/open_spiel/abseil-cpp
mv dds-0.1.0 open_spiel/open_spiel/games/bridge/double_dummy_solver
mv hanabi-learning-environment-0.1.0 open_spiel/open_spiel/games/hanabi/hanabi-learning-environment
mv project_acpc_server-0.1.0 open_spiel/open_spiel/games/universal_poker/acpc

mkdir open_spiel/build
cd open_spiel/build
export BUILD_WITH_PYTHON=OFF BUILD_WITH_JULIA=ON BUILD_WITH_HANABI=ON BUILD_WITH_ACPC=OFF
cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    ../open_spiel/
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/open_spiel/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)


# The products that we will ensure are always built
products = [
    LibraryProduct("libspieljl", :libspieljl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    Dependency("libcxxwrap_julia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10",
    julia_compat = "$(julia_version.major).$(julia_version.minor)")
