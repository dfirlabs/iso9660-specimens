#!/bin/bash
#
# Shared functionality for scripts to generate ISO 9660 test files

EXIT_SUCCESS=0
EXIT_FAILURE=1

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
    local BINARY=$1

    which "${BINARY}" > /dev/null 2>&1
    if test $? -ne ${EXIT_SUCCESS}
    then
        echo "Missing binary: ${BINARY}"
        echo ""

        exit ${EXIT_FAILURE}
    fi
}

# Creates test file entries.
#
# Arguments:
#   a string containing the mount point of the image file
#
create_test_file_entries()
{
    MOUNT_POINT=$1

    # Create an empty file
    touch "${MOUNT_POINT}/emptyfile"

    # Create a directory
    mkdir "${MOUNT_POINT}/testdir1"

    # Create a file that can be stored as inline data
    echo "My file" > "${MOUNT_POINT}/testdir1/testfile1"

    # Create a file that cannot be stored as inline data
    cp LICENSE "${MOUNT_POINT}/testdir1/TestFile2"

    # Create a hard link to a file
    ln "${MOUNT_POINT}/testdir1/testfile1" "${MOUNT_POINT}/file_hardlink1"

    # Create a symbolic link to a file
    ln -s "${MOUNT_POINT}/testdir1/testfile1" "${MOUNT_POINT}/file_symboliclink1"

    # Create a hard link to a directory
    # ln: hard link not allowed for directory

    # Create a symbolic link to a directory
    ln -s "${MOUNT_POINT}/testdir1" "${MOUNT_POINT}/directory_symboliclink1"

    # Create a file with an UTF-8 NFC encoded filename
    FILE_NAME=$(printf "%s/nfc_t\xc3\xa9stfil\xc3\xa8" "${MOUNT_POINT}")
    touch "${FILE_NAME}"

    # Create a file with an UTF-8 NFD encoded filename
    FILE_NAME=$(printf "%s/nfd_te\xcc\x81stfile\xcc\x80" "${MOUNT_POINT}")
    touch "${FILE_NAME}"

    # Create a file with an UTF-8 NFD encoded filename
    FILE_NAME=$(printf "%s/nfd_\xc2\xbe" "${MOUNT_POINT}")
    touch "${FILE_NAME}"

    # Create a file with an UTF-8 NFKD encoded filename
    FILE_NAME=$(printf "%s/nfkd_3\xe2\x81\x844" "${MOUNT_POINT}")
    touch "${FILE_NAME}"

    # Create a file with an extended attribute
    touch "${MOUNT_POINT}/testdir1/xattr1"
    setfattr -n "user.myxattr1" -v "My 1st extended attribute" "${MOUNT_POINT}/testdir1/xattr1"

    # Create a directory with an extended attribute
    mkdir "${MOUNT_POINT}/testdir1/xattr2"
    setfattr -n "user.myxattr2" -v "My 2nd extended attribute" "${MOUNT_POINT}/testdir1/xattr2"

    # Create a file with an initial (implict) sparse extent
    truncate -s $(( 1 * 1024 * 1024 )) "${MOUNT_POINT}/testdir1/initial_sparse1"
    echo "File with an initial sparse extent" >> "${MOUNT_POINT}/testdir1/initial_sparse1"

    # Create a file with a trailing (implict) sparse extent
    echo "File with a trailing sparse extent" > "${MOUNT_POINT}/testdir1/trailing_sparse1"
    truncate -s $(( 1 * 1024 * 1024 )) "${MOUNT_POINT}/testdir1/trailing_sparse1"

    # Create a file with an uninitialized extent
    fallocate -x -l 4096 "${MOUNT_POINT}/testdir1/uninitialized1"
    echo "File with an uninitialized extent" >> "${MOUNT_POINT}/testdir1/uninitialized1"
}

# Creates a test image file.
#
# Arguments:
#   a string containing the path of the image file
#   an integer containing the size of the image file
#   an integer containing the sector size
#   an array containing the arguments for mke2fs
#
create_test_image_file()
{
    IMAGE_FILE=$1
    IMAGE_SIZE=$2
    SECTOR_SIZE=$3
    shift 3

    dd if=/dev/zero of="${IMAGE_FILE}" bs="${SECTOR_SIZE}" count=$(( IMAGE_SIZE / SECTOR_SIZE )) 2> /dev/null

    # Notes:
    # -N #  the minimum number of inodes seems to be 16
    # shellcheck disable=SC2068
    mke2fs -q $@ "${IMAGE_FILE}"
}

# Creates a test image file with file entries.
#
# Arguments:
#   a string containing the path of the image file
#   an integer containing the size of the image file
#   an integer containing the sector size
#   an array containing the arguments for mke2fs
#
create_test_image_file_with_file_entries()
{
    IMAGE_FILE=$1
    IMAGE_SIZE=$2
    SECTOR_SIZE=$3
    shift 3

    # shellcheck disable=SC2068
    create_test_image_file "${IMAGE_FILE}" "${IMAGE_SIZE}" "${SECTOR_SIZE}" $@

    sudo mount -o loop,rw "${IMAGE_FILE}" "${MOUNT_POINT}"

    sudo chown "${USERNAME}" "${MOUNT_POINT}"

    create_test_file_entries "${MOUNT_POINT}"

    sudo umount "${MOUNT_POINT}"
}
