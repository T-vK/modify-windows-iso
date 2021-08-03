#!/usr/bin/env bash

#####################################################################################################
# Builds and compiles the Schily Tools
# This is needed for the modify-windows-iso.sh script
# We only really need the special version of mkisofs that are in Schily Tools
# Usage: `./schily-tools-setup.sh`
#####################################################################################################

function commandsAvailable() {
    commandsMissing=()
    for currentCommand in $1; do
        if ! command -v $currentCommand &> /dev/null; then
            commandsMissing+=("$currentCommand")
        fi
    done
    if ((${#commandsMissing[@]})); then
        echo "Missing commands: ${commandsMissing[@]}"
        return 1 # Some commands are missing
    else
        return 0
    fi
}

if ! commandsAvailable "wget imake g++"; then
    echo "Required packages are missing. Make sure you have wget imake g++ installed. You also need the package providing 'include/ext2fs/ext2fs.h'. On Debian/Ubuntu it may come with the package e2fslibs-dev and on Fedora it comes with the package e2fsprogs-devel"
else
    echo "Seems like the required packages are installed."
fi


SCHILY_VERSION="2021-06-07"
SCHILY_ARCHIVE="schily-${SCHILY_VERSION}.tar.bz2"
SCHILY_DIR="./schily-tools"
sudo rm -rf "${SCHILY_DIR}"
wget "https://altushost-swe.dl.sourceforge.net/project/schilytools/${SCHILY_ARCHIVE}" -O "${SCHILY_ARCHIVE}"
tar -xf "${SCHILY_ARCHIVE}"
rm "${SCHILY_ARCHIVE}"
mv "schily-${SCHILY_VERSION}" "${SCHILY_DIR}"
cd "${SCHILY_DIR}"
./Gmake.linux

echo "If the build was successful you can now use it like this:"
echo "./schily-tools/mkisofs/OBJ/x86_64-linux-gcc/mkisofs --help"
