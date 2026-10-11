#!/bin/bash
#
# Script to generate ISO 9660 test files
# Requires Linux with xorriso

source ./shared_linux.sh

assert_availability_binary xorriso

VERSION=$( xorriso -version 2>&1 | head -n1 | sed 's/^xorriso \([0-9]*.[0-9]*.[0-9]*\).*$/\1/' )

SPECIMENS_PATH="specimens/xorriso-${VERSION}"

if test -d "${SPECIMENS_PATH}"
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p "${SPECIMENS_PATH}"

TARGET_ISO="${SPECIMENS_PATH}/multiple_versions_single_session.iso"

mkdir -p x/
echo "Initial content (Version 1)" > "x/DATA.TXT;1"
echo "Updated content (Version 2)" > "x/DATA.TXT;2"
echo "Final content (Version 3)" > "x/DATA.TXT;3"
echo "Another Version 1" > "x/DATA.TXT.;1"
echo "More Version 1" > "x/DA;1TA.TXT.;1"

xorriso \
  --rockridge off \
  -as mkisofs \
  -o "${TARGET_ISO}" \
  -iso-level 1 \
  -untranslated-filenames \
  -graft-points \
  "/=x/"

rm -rf x
