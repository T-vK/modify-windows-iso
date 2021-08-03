#!/usr/bin/env bash

#####################################################################################################
# WARNING: THIS SCRIPT CAN INDEED MODIFY A WINDOWS 10 ISO, BUT THE RESULTING ISO WON'T BE AS CLEAN AS THE ORIGINAL ONE!
#          E.G. IT MAY ONLY BOOT IN UEFI MODE AND SOME IDS MAY BE DIFFERENT
#          IT SHOULD HOWEVER WORK FINE FOR A CLEAN WINDOWS INSTALLATION WHERE A NOT LEGACY BOOT IS REQUIRED.
# This script has to be called like this: `./modify-windows-iso.sh /path/to/mywindows.iso`
#####################################################################################################

# Variable containing the path to the windows.iso
WIN10_IMG="$1"

TMP="./tmp"
ISO_FILES="${TMP}/iso-files"
ISO_MP="${TMP}/iso-mountpoint"

sudo rm -rf "${TMP}"
mkdir -p "${ISO_FILES}"
mkdir -p "${ISO_MP}"
sudo mount -t udf "${WIN10_IMG}" "${ISO_MP}"
sudo cp -Rva ${ISO_MP}/* "${ISO_FILES}"
sudo umount "${ISO_MP}"





# Make your modifications to the Windows ISO HERE




# Extract boot load segment address and size
BOOT_LOAD_SEG="$(dumpet -i "${WIN10_IMG}" | grep "Media load segment: " | cut -d ':' -f2 | cut -d ' ' -f2)"
BOOT_LOAD_SIZE="$(dumpet -i "${WIN10_IMG}" | grep "Load Sectors: " | grep -o "[^:]*$" | cut -d ' ' -f2 | head -1)"

EFI_STARTING_SECTOR="$(dumpet -i "${WIN10_IMG}" | grep "Load LBA: " | grep -o "[^:]*$" | cut -d ' ' -f2 | tail -1)"

echo "EFI_STARTING_SECTOR: $EFI_STARTING_SECTOR"

sudo dd if="${WIN10_IMG}" of="${ISO_FILES}/efi.dmp" bs=2048 count=1 skip="${EFI_STARTING_SECTOR}"
EFI_BOOT_LOAD_SIZE="$(file "${ISO_FILES}/efi.dmp" | grep -oP 'sectors (\d+)' | cut -d ' ' -f2)"
echo "EFI_BOOT_LOAD_SIZE: $EFI_BOOT_LOAD_SIZE"
sudo rm -f "${ISO_FILES}/efi.dmp"
sudo rm -f "${ISO_FILES}/efi/win_efi_boot.img"
sudo dd if="${WIN10_IMG}" of="${ISO_FILES}/efi/win_efi_boot.img" bs=2048 count="${EFI_BOOT_LOAD_SIZE}" skip="${EFI_STARTING_SECTOR}"

# Extract meta data :
SYSTEM_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "System id: " | cut -d ' ' -f3-)"
VOLUME_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Volume id: " | cut -d ' ' -f3-)"
VOLUME_SET_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Volume set id: " | cut -d ' ' -f4-)"
PUBLISHER_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Publisher id: " | cut -d ' ' -f3-)" # Always uppercase
ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "ID '" | cut -d "'" -f2)"
DATA_PREPARER_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Data preparer id: " | cut -d ' ' -f4-)"
APPLICATION_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Application id: " | cut -d ' ' -f3-)"
COPYRIGHT_FILE_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Copyright file id: " | cut -d ' ' -f4-)"
ABSTRACT_FILE_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Abstract file id: " | cut -d ' ' -f4-)"
BIBLIOGRAPHIC_FILE_ID="$(isoinfo -d -i "${WIN10_IMG}" | grep "Bibliographic file id: " | cut -d ' ' -f4-)"


sudo rm -f "${WIN10_IMG}.tmp.iso"
sudo "./schily-tools/mkisofs/OBJ/x86_64-linux-gcc/mkisofs" \
  -appid "${APPLICATION_ID}" \
  -copyright "${COPYRIGHT_FILE_ID}" \
  -abstract "${ABSTRACT_FILE_ID}" \
  -biblio "${BIBLIOGRAPHIC_FILE_ID}" \
  -preparer "${DATA_PREPARER_ID}" \
  -publisher "${PUBLISHER_ID}" \
  -sysid "${SYSTEM_ID}" \
  -volid "${VOLUME_ID}" \
  -volset "${VOLUME_SET_ID}" \
  -no-emul-boot \
  -b boot/etfsboot.com \
  -boot-load-seg "${BOOT_LOAD_SEG}" \
  -boot-load-size "${BOOT_LOAD_SIZE}" \
  -eltorito-alt-boot \
  -no-emul-boot \
  -eltorito-boot "efi/win_efi_boot.img" \
  -boot-load-size 1 \
  -iso-level 4 \
  -UDF \
  -o "${WIN10_IMG}.tmp.iso" \
  "${ISO_FILES}"

  #-e boot.efi.img \
  #-boot-info-table \
  #-D \
  #-N \
  #-relaxed-filenames \
  #-allow-lowercase \
  #-o "${WIN10_IMG}.tmp.iso" \
  #"${ISO_FILES}"


echo "BOOT_LOAD_SEG: ${BOOT_LOAD_SEG}"
echo "BOOT_LOAD_SIZE: ${BOOT_LOAD_SIZE}"
echo "-------"
echo "SYSTEM_ID: ${SYSTEM_ID}"
echo "VOLUME_ID: ${VOLUME_ID}"
echo "VOLUME_SET_ID: ${VOLUME_SET_ID}"
echo "PUBLISHER_ID: ${PUBLISHER_ID}"
echo "ID: ${ID}"
echo "DATA_PREPARER_ID: ${DATA_PREPARER_ID}"
echo "APPLICATION_ID: ${APPLICATION_ID}"
echo "COPYRIGHT_FILE_ID: ${COPYRIGHT_FILE_ID}"
echo "ABSTRACT_FILE_ID: ${ABSTRACT_FILE_ID}"
echo "BIBLIOGRAPHIC_FILE_ID: ${BIBLIOGRAPHIC_FILE_ID}"


# Show difference between new and old image as reported by isoinfo
echo
echo "-------------- isoinfo diff -----------------"
colordiff <(isoinfo -d -i "${WIN10_IMG}") <(isoinfo -d -i "${WIN10_IMG}.tmp.iso")

# Show difference between new and old image as reported by dumpet
echo
echo " -------------- dumpet diff -----------------"
colordiff <(dumpet -i "${WIN10_IMG}") <(dumpet -i "${WIN10_IMG}.tmp.iso")



# Method from: https://www.g-loaded.eu/2007/04/25/how-to-create-a-windows-bootable-cd-with-mkisofs/
#sudo mkisofs -o "${WIN10_IMG}.tmp.iso" -b "boot.img" -no-emul-boot -boot-load-seg 1984 -boot-load-size 4 \
#    -iso-level 2 -udf \
#    -J -l -D -N -joliet-long -relaxed-filenames "${ISO_FILES}"

#sudo mkisofs \
#    -b "boot.img" -no-emul-boot -boot-load-seg 1984 -boot-load-size 4 \
#    -iso-level 2 -J -l -D -N -joliet-long -relaxed-filenames \
#    -V "WINDOWS10_AUTOBOOT" \
#    -o "${WIN10_IMG}.tmp.iso" "${ISO_FILES}"


#sudo mkisofs -D -r -V "WINDOWS10_AUTOBOOT" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "${WIN10_IMG}.tmp" "${ISO_FILES}"
#sudo rm "${WIN10_IMG}"
#sudo mv "${WIN10_IMG}.tmp.iso" "${WIN10_IMG}"
