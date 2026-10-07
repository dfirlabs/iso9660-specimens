#!/bin/bash
#
# Script to generate ISO 9660 test files
# Requires Linux with genisoimage

source ./shared_linux.sh

assert_availability_binary dd
assert_availability_binary fallocate
assert_availability_binary genisoimage
assert_availability_binary mke2fs
assert_availability_binary setfattr
assert_availability_binary truncate

VERSION=$( genisoimage -version | sed 's/genisoimage \(\S*\) .*/\1/' )

SPECIMENS_PATH="specimens/genisoimage-${VERSION}"

if test -d "${SPECIMENS_PATH}"
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p "${SPECIMENS_PATH}"

set -e

USERNAME=$( whoami )

MOUNT_POINT="/mnt/ext"

sudo mkdir -p "${MOUNT_POINT}"

# Create an ext2 file system without a journal
IMAGE_FILE="${SPECIMENS_PATH}/ext2.raw"

create_test_image_file_with_file_entries "${IMAGE_FILE}" $(( 4096 * 1024 )) 512 "-L ext2_test" "-t ext2"

sudo mount -o loop,rw "${IMAGE_FILE}" "${MOUNT_POINT}"

# Level 1: files may only consist of one section and filenames are restricted to 8.3 characters.
genisoimage -input-charset utf8 -iso-level 1 -o "${SPECIMENS_PATH}/iso9660-level1.raw" "${MOUNT_POINT}"

# Level 2: files may only consist of one section.
genisoimage -input-charset utf8 -iso-level 2 -o "${SPECIMENS_PATH}/iso9660-level2.raw" "${MOUNT_POINT}"

# Level 3: no restrictions (other than ISO-9660:1988) do apply.
genisoimage -input-charset utf8 -iso-level 3 -o "${SPECIMENS_PATH}/iso9660-level3.raw" "${MOUNT_POINT}"

# Level 4: ISO 9660 version 2 (ISO-9660:1999).
genisoimage -input-charset iso8859-1 -iso-level 4 -o "${SPECIMENS_PATH}/iso9660-level4.raw" "${MOUNT_POINT}"

genisoimage -input-charset utf8 -joliet -o "${SPECIMENS_PATH}/iso9660-joliet.raw" "${MOUNT_POINT}"

genisoimage -input-charset utf8 -joliet -joliet-long -o "${SPECIMENS_PATH}/iso9660-joliet-long.raw" "${MOUNT_POINT}"

genisoimage -input-charset utf8 -rock -o "${SPECIMENS_PATH}/iso9660-rock.raw" "${MOUNT_POINT}"

genisoimage -input-charset utf8 -XA -o "${SPECIMENS_PATH}/iso9660-xa.raw" "${MOUNT_POINT}"

genisoimage -input-charset iso8859-1 -apple -rock -o "${SPECIMENS_PATH}/iso9660-apple-rock.raw" "${MOUNT_POINT}"

genisoimage -input-charset iso8859-1 -apple -XA -o "${SPECIMENS_PATH}/iso9660-apple-xa.raw" "${MOUNT_POINT}"

genisoimage -input-charset iso8859-1 -hfs -rock -o "${SPECIMENS_PATH}/iso9660-hfs-rock.raw" "${MOUNT_POINT}"

genisoimage -input-charset iso8859-1 -hfs -XA -o "${SPECIMENS_PATH}/iso9660-hfs-xa.raw" "${MOUNT_POINT}"

sudo umount "${MOUNT_POINT}"

rm -f "${IMAGE_FILE}"
