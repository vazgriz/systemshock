#!/bin/bash
set -e

SDL_version=2.0.8
SDL_mixer_version=2.0.2
CMAKE_version=3.11.3
#CMAKE_architecture=win64-x64
CMAKE_architecture=win32-x86
install_dir=`pwd -W`

# Removing the mwindows linker option lets us get console output
function remove_mwindows {
	sed -i -e "s/ \-mwindows//g" Makefile
}

function build_sdl {
	curl -O https://www.libsdl.org/release/SDL2-${SDL_version}.tar.gz
	tar xvf SDL2-${SDL_version}.tar.gz
	pushd SDL2-${SDL_version}

	./configure "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32"
	remove_mwindows
	make
	make install

	popd
}

function build_sdl_mixer {
	git clone https://github.com/SDL-mirror/SDL_mixer.git
	pushd SDL_mixer

	./configure "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32"
	remove_mwindows
	make
	make install

	popd
}

function get_cmake {
	curl -O https://cmake.org/files/v3.11/cmake-${CMAKE_version}-${CMAKE_architecture}.zip
	unzip cmake-${CMAKE_version}-${CMAKE_architecture}.zip
	pushd cmake-${CMAKE_version}-${CMAKE_architecture}/bin
	CMAKE_ROOT=`pwd -W`/
	popd
}

## Actual building starts here

if [ -d ./build_ext/ ]; then
	echo A directory named build_ext already exists.
	echo Please remove it if you want to recompile.
	exit
fi

rm -rf CMakeFiles/
rm -rf CMakeCache.txt

cp windows/make.exe /usr/bin/
mkdir ./build_ext/
cd ./build_ext/

build_sdl
build_sdl_mixer

if ! [ -x "$(command -v cmake)" ]; then
	echo "Getting CMake"
	get_cmake
fi

# Back to the root directory, copy SDL DLL files for the executable
cd ..
cp /usr/local/bin/*.dll .

# Set up build.bat
# TODO: conditional on whether CMake was downloaded
echo "@set PATH=%PATH%;${CMAKE_ROOT}
cmake -G \"MinGW Makefiles\" .
mingw32-make systemshock" >build.bat

echo "Our work here is done. Run BUILD.BAT in a Windows shell to build the actual source."
