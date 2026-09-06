#!/usr/bin/env python3
"""
package_qdl.py

Packages LineageOS 23.2 (Android 16) for Arduino Uno Q (Imola) into a 
standalone QDL (Qualcomm Emergency Download / EDL mode) flash package.

Boot chain architecture:
  Qualcomm PBL -> XBL -> TrustZone/Hyp -> ABL (Das U-Boot 2026.01) -> boot.scr -> booti -> Android 16

Output contains:
  - prog_firehose_ddr.elf (EDL programmer from qcombin)
  - Qualcomm silicon firmware binaries (xbl, tz, rpm, hyp, abl/u-boot, devcfg, etc.)
  - gpt_main0.bin & gpt_backup0.bin (configured with efi, super, metadata, userdata)
  - rawprogram0.xml & patch0.xml (EDL flash scripts)
  - efi.img (512MB FAT32 boot partition containing boot.scr, Image, ramdisk.img, dtb.img)
  - super.img (Android dynamic partitions: system, vendor, product, system_ext, dlkm)
  - flash.sh (Convenient one-click flashing script)
"""

import argparse
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET
import zlib

# Default disk geometry for 32GB eMMC on Arduino Uno Q
TOTAL_DISK_SECTORS = 61071360  # ~29.1 GiB usable
LAST_USABLE_LBA = TOTAL_DISK_SECTORS - 34  # 61071326

# Partition Layout (Sectors: 512 bytes each)
# P67: efi (512MB)
EFI_START_SECTOR = 985408
EFI_SECTORS = 1048576  # 512 MB
EFI_END_SECTOR = EFI_START_SECTOR + EFI_SECTORS - 1  # 2033983

# P68: super (4096MB)
SUPER_START_SECTOR = 2033984
SUPER_SECTORS = 8388608  # 4096 MB
SUPER_END_SECTOR = SUPER_START_SECTOR + SUPER_SECTORS - 1  # 10422591

# P69: metadata (64MB)
METADATA_START_SECTOR = 10422592
METADATA_SECTORS = 131072  # 64 MB
METADATA_END_SECTOR = METADATA_START_SECTOR + METADATA_SECTORS - 1  # 10553663

# P70: userdata (Fill remaining eMMC up to LAST_USABLE_LBA)
USERDATA_START_SECTOR = 10553664
USERDATA_END_SECTOR = LAST_USABLE_LBA
USERDATA_SECTORS = USERDATA_END_SECTOR - USERDATA_START_SECTOR + 1  # ~24.09 GB

LINUX_FS_GUID = uuid.UUID("0fc63daf-8483-4772-8e79-3d69d8477de4").bytes_le


def make_uimage_script(script_text: str) -> bytes:
    """Wraps shell script text in a standard U-Boot script uImage header with 8-byte subheader."""
    script_bytes = script_text.encode("utf-8")
    # U-Boot cmd/source.c expects an 8-byte subheader before the script text:
    # 4 bytes: length of script string (uint32 big-endian)
    # 4 bytes: padding/reserved (0x00000000)
    payload = struct.pack(">II", len(script_bytes), 0) + script_bytes
    size = len(payload)
    dcrc = zlib.crc32(payload) & 0xFFFFFFFF
    t = int(time.time())
    hdr_no_crc = struct.pack(">IIIIIIIBBBB32s", 0x27051956, 0, t, size, 0, 0, dcrc, 5, 2, 6, 0, b"")
    hcrc = zlib.crc32(hdr_no_crc) & 0xFFFFFFFF
    hdr = struct.pack(">IIIIIIIBBBB32s", 0x27051956, hcrc, t, size, 0, 0, dcrc, 5, 2, 6, 0, b"")
    return hdr + payload


def make_uimage_ramdisk(ramdisk_bytes: bytes) -> bytes:
    """Wraps ramdisk in a standard U-Boot ramdisk uImage header (uInitrd)."""
    size = len(ramdisk_bytes)
    dcrc = zlib.crc32(ramdisk_bytes) & 0xFFFFFFFF
    t = int(time.time())
    # magic 0x27051956, os: 5 (Linux), arch: 2 (ARM), type: 3 (Ramdisk), comp: 0 (None)
    hdr_no_crc = struct.pack(">IIIIIIIBBBB32s", 0x27051956, 0, t, size, 0, 0, dcrc, 5, 2, 3, 0, b"")
    hcrc = zlib.crc32(hdr_no_crc) & 0xFFFFFFFF
    hdr = struct.pack(">IIIIIIIBBBB32s", 0x27051956, hcrc, t, size, 0, 0, dcrc, 5, 2, 3, 0, b"")
    return hdr + ramdisk_bytes


def create_gpt_entry(name, first_lba, last_lba, type_guid_bytes=LINUX_FS_GUID, flags=0):
    uniq_guid = uuid.uuid4().bytes_le
    name_bytes = name.encode("utf-16le").ljust(72, b"\x00")[:72]
    return struct.pack("<16s16sQQQ", type_guid_bytes, uniq_guid, first_lba, last_lba, flags) + name_bytes


def patch_gpt_tables(qcombin_board_dir, out_dir):
    src_main = os.path.join(qcombin_board_dir, "gpt_main0.bin")
    src_backup = os.path.join(qcombin_board_dir, "gpt_backup0.bin")

    with open(src_main, "rb") as f:
        main_data = bytearray(f.read())
    with open(src_backup, "rb") as f:
        backup_data = bytearray(f.read())

    # GPT Partition Entries start at sector 2 (offset 1024) in gpt_main0.bin
    # P67 (index 66): efi (512MB)
    # P68 (index 67): super (4096MB)
    # P69 (index 68): metadata (64MB)
    # P70 (index 69): userdata (~24.1GB)

    entry_super = create_gpt_entry("super", SUPER_START_SECTOR, SUPER_END_SECTOR, LINUX_FS_GUID, 0)
    entry_metadata = create_gpt_entry("metadata", METADATA_START_SECTOR, METADATA_END_SECTOR, LINUX_FS_GUID, 0)
    entry_userdata = create_gpt_entry("userdata", USERDATA_START_SECTOR, USERDATA_END_SECTOR, LINUX_FS_GUID, 0)

    # Insert into main GPT (offset = 1024 + idx * 128)
    main_data[1024 + 67 * 128 : 1024 + 68 * 128] = entry_super
    main_data[1024 + 68 * 128 : 1024 + 69 * 128] = entry_metadata
    main_data[1024 + 69 * 128 : 1024 + 70 * 128] = entry_userdata

    # In backup GPT, partition entries start at sector 0 (offset 0..16384)
    # Mirror the entire 32 sectors of partition entries
    backup_data[0:16384] = main_data[1024:17408]

    dst_main = os.path.join(out_dir, "gpt_main0.bin")
    dst_backup = os.path.join(out_dir, "gpt_backup0.bin")

    with open(dst_main, "wb") as f:
        f.write(main_data)
    with open(dst_backup, "wb") as f:
        f.write(backup_data)

    print(f"[+] Successfully generated Android GPT tables:")
    print(f"    - P67 efi:      {EFI_START_SECTOR} .. {EFI_END_SECTOR} (512 MB)")
    print(f"    - P68 super:    {SUPER_START_SECTOR} .. {SUPER_END_SECTOR} (4096 MB)")
    print(f"    - P69 metadata: {METADATA_START_SECTOR} .. {METADATA_END_SECTOR} (64 MB)")
    print(f"    - P70 userdata: {USERDATA_START_SECTOR} .. {USERDATA_END_SECTOR} (~{(USERDATA_SECTORS*512)/(1024**3):.2f} GB)")


def generate_rawprogram(src_xml, dst_xml):
    tree = ET.parse(src_xml)
    root = tree.getroot()

    new_programs = []

    for p in list(root):
        label = p.get("label", "")
        fn = p.get("filename", "")

        # Clean relative path prefixes
        if fn.startswith("../"):
            p.set("filename", os.path.basename(fn))

        # boot_a and boot_b are 4MB dummy partitions on Uno Q.
        # Clear filename so qdl doesn't fail trying to flash whole boot images to 4MB.
        if label in ["boot_a", "boot_b"]:
            p.set("filename", "")

        if label == "efi":
            p.set("filename", "efi.img")
            p.set("size_in_KB", "524288.0")
            p.set("num_partition_sectors", str(EFI_SECTORS))
            p.set("start_sector", str(EFI_START_SECTOR))
            p.set("start_byte_hex", hex(EFI_START_SECTOR * 512))
            new_programs.append(p)

        elif label == "rootfs":
            # Replace rootfs with super
            p_super = ET.Element("program", {
                "start_sector": str(SUPER_START_SECTOR),
                "size_in_KB": "4194304.0",
                "physical_partition_number": "0",
                "partofsingleimage": "false",
                "file_sector_offset": "0",
                "num_partition_sectors": str(SUPER_SECTORS),
                "readbackverify": "false",
                "filename": "super.img",
                "sparse": "false",
                "start_byte_hex": hex(SUPER_START_SECTOR * 512),
                "SECTOR_SIZE_IN_BYTES": "512",
                "label": "super",
            })
            new_programs.append(p_super)

            # Add metadata partition (wipe first 33 sectors)
            p_metadata = ET.Element("program", {
                "start_sector": str(METADATA_START_SECTOR),
                "size_in_KB": "16.5",
                "physical_partition_number": "0",
                "partofsingleimage": "false",
                "file_sector_offset": "0",
                "num_partition_sectors": "33",
                "readbackverify": "false",
                "filename": "zeros_33sectors.bin",
                "sparse": "false",
                "start_byte_hex": hex(METADATA_START_SECTOR * 512),
                "SECTOR_SIZE_IN_BYTES": "512",
                "label": "metadata",
            })
            new_programs.append(p_metadata)

            # Add userdata partition (wipe first 33 sectors to trigger clean format on first boot)
            p_userdata = ET.Element("program", {
                "start_sector": str(USERDATA_START_SECTOR),
                "size_in_KB": "16.5",
                "physical_partition_number": "0",
                "partofsingleimage": "false",
                "file_sector_offset": "0",
                "num_partition_sectors": "33",
                "readbackverify": "false",
                "filename": "zeros_33sectors.bin",
                "sparse": "false",
                "start_byte_hex": hex(USERDATA_START_SECTOR * 512),
                "SECTOR_SIZE_IN_BYTES": "512",
                "label": "userdata",
            })
            new_programs.append(p_userdata)

        elif label == "userdata":
            # Skip old placeholder userdata
            continue
        else:
            new_programs.append(p)

    # Rebuild root
    root.clear()
    for p in new_programs:
        root.append(p)

    # Write out cleanly formatted XML
    ET.indent(tree, space="  ", level=0)
    tree.write(dst_xml, encoding="utf-8", xml_declaration=True)
    print(f"[+] Successfully generated Android {os.path.basename(dst_xml)}")


def build_efi_image(out_path, kernel_path, ramdisk_path, dtb_path, cmdline):
    print(f"[*] Building 512MB boot partition ({out_path})...")

    mkfs_vfat = shutil.which("mkfs.vfat") or "/usr/sbin/mkfs.vfat"
    if not os.path.isfile(mkfs_vfat) and not shutil.which("mkfs.vfat"):
        sys.exit("[-] ERROR: 'mkfs.vfat' is required. Run: sudo apt install -y dosfstools")

    mcopy = shutil.which("mcopy")
    mmd = shutil.which("mmd")
    if not mcopy or not mmd:
        sys.exit("[-] ERROR: 'mtools' (mcopy, mmd) is required to build efi.img.\n    Please run: sudo apt install -y mtools")

    # 1. Allocate 512MB empty image
    with open(out_path, "wb") as f:
        f.truncate(512 * 1024 * 1024)

    # 2. Format as FAT32
    cmd = [mkfs_vfat, "-F", "32", "-n", "EFI", out_path]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)

    # 3. Create /extlinux directory
    subprocess.run([mmd, "-i", out_path, "::/extlinux"], check=True, stdout=subprocess.DEVNULL)

    # 4. Generate boot configs
    with tempfile.TemporaryDirectory() as tmp_dir:
        # A) Native U-Boot boot.cmd & boot.scr
        boot_cmd_text = (
            "# LineageOS 23.2 U-Boot Boot Script for Arduino Uno Q (Imola)\n"
            'setenv kernel_addr_r "0x42000000"\n'
            'setenv fdt_addr_r "0x48000000"\n'
            'setenv ramdisk_addr_r "0x82000000"\n'
            'setenv devtype "mmc"\n'
            'setenv devnum "0"\n'
            'test -n "${distro_bootpart}" || setenv distro_bootpart "43"\n'
            f'setenv bootargs "{cmdline}"\n'
            "echo \"Loading LineageOS 23.2 Android 16 kernel, ramdisk, dtb...\"\n"
            "load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} Image\n"
            "load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} ramdisk.img\n"
            "setenv ramdisk_size ${filesize}\n"
            "load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} dtb.img\n"
            "echo \"Booting Android 16 via booti...\"\n"
            "booti ${kernel_addr_r} ${ramdisk_addr_r}:${ramdisk_size} ${fdt_addr_r}\n"
        )
        boot_cmd_file = os.path.join(tmp_dir, "boot.cmd")
        with open(boot_cmd_file, "w") as f:
            f.write(boot_cmd_text)

        boot_scr_file = os.path.join(tmp_dir, "boot.scr")
        with open(boot_scr_file, "wb") as f:
            f.write(make_uimage_script(boot_cmd_text))

        # B) extlinux.conf
        extlinux_conf_text = (
            "default LineageOS\n"
            "timeout 10\n"
            "\n"
            "label LineageOS\n"
            "  menu label LineageOS 23.2 (Android 16)\n"
            "  kernel /Image\n"
            "  initrd /ramdisk.img\n"
            "  fdt /dtb.img\n"
            f"  append {cmdline}\n"
        )
        extlinux_conf_file = os.path.join(tmp_dir, "extlinux.conf")
        with open(extlinux_conf_file, "w") as f:
            f.write(extlinux_conf_text)

        # C) uInitrd (uImage wrapped ramdisk)
        uinitrd_file = os.path.join(tmp_dir, "uInitrd")
        with open(ramdisk_path, "rb") as rf:
            ramdisk_data = rf.read()
        with open(uinitrd_file, "wb") as uf:
            uf.write(make_uimage_ramdisk(ramdisk_data))

        # 5. Copy boot configs and OS artifacts into FAT32 partition
        subprocess.run([mcopy, "-i", out_path, boot_cmd_file, "::/boot.cmd"], check=True)
        subprocess.run([mcopy, "-i", out_path, boot_scr_file, "::/boot.scr"], check=True)
        subprocess.run([mcopy, "-i", out_path, extlinux_conf_file, "::/extlinux/extlinux.conf"], check=True)
        subprocess.run([mcopy, "-i", out_path, kernel_path, "::/Image"], check=True)
        subprocess.run([mcopy, "-i", out_path, ramdisk_path, "::/ramdisk.img"], check=True)
        subprocess.run([mcopy, "-i", out_path, uinitrd_file, "::/uInitrd"], check=True)
        subprocess.run([mcopy, "-i", out_path, dtb_path, "::/dtb.img"], check=True)
        subprocess.run([mcopy, "-i", out_path, dtb_path, "::/qrb2210-arduino-imola.dtb"], check=True)

    print(f"[+] efi.img created successfully ({os.path.getsize(out_path) // (1024*1024)} MB).")
    print(f"    - Native U-Boot Script:     /boot.scr (with 8-byte subheader)")
    print(f"    - Extlinux Config:          /extlinux/extlinux.conf")
    print(f"    - Android Kernel Image:     /Image")
    print(f"    - Ramdisk / uInitrd:        /ramdisk.img & /uInitrd")
    print(f"    - Device Tree Blob:         /dtb.img & /qrb2210-arduino-imola.dtb")


def process_super_image(src_super, dst_super, simg2img_bin):
    print(f"[*] Processing super.img: {src_super} -> {dst_super}")
    with open(src_super, "rb") as f:
        magic = f.read(4)

    is_sparse = (magic == b"\x3a\xff\x26\xed")
    if is_sparse:
        print("[*] super.img is an Android sparse image. Converting to raw unsparse image...")
        if not simg2img_bin or not os.path.isfile(simg2img_bin):
            sys.exit(f"[-] ERROR: simg2img binary not found! Needed to unsparse {src_super}")
        subprocess.run([simg2img_bin, src_super, dst_super], check=True)
    else:
        print("[*] super.img is already a raw image. Creating hardlink/copy...")
        if os.path.exists(dst_super):
            os.remove(dst_super)
        try:
            os.link(src_super, dst_super)
        except OSError:
            shutil.copy2(src_super, dst_super)

    print(f"[+] super.img ready (size: {os.path.getsize(dst_super) // (1024*1024)} MB).")


def generate_flash_script(out_dir):
    script_path = os.path.join(out_dir, "flash.sh")
    content = """#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "========================================================"
echo " Arduino Uno Q (Imola) - Pure LineageOS 23.2 Flasher"
echo "========================================================"

if ! command -v qdl &>/dev/null; then
    echo "[-] ERROR: 'qdl' tool not found!"
    echo "    Install it via: sudo apt install -y qdl"
    exit 1
fi

echo "[*] Checking for Arduino Uno Q in EDL Mode (05c6:9008)..."
if ! lsusb -d 05c6:9008 >/dev/null 2>&1; then
    echo "[-] Device not found in EDL mode (05c6:9008)."
    echo "    Please set the EDL jumper / test point on the Arduino Uno Q"
    echo "    and reconnect the USB-C cable to your computer."
    exit 1
fi
echo "[+] Detected Arduino Uno Q in EDL mode!"

# Check USB device permissions
if [ "${EUID}" -ne 0 ]; then
    DEV_PATH=$(lsusb -d 05c6:9008 | awk '{print "/dev/bus/usb/" $2 "/" substr($4, 1, 3)}')
    if [ -n "${DEV_PATH}" ] && [ ! -w "${DEV_PATH}" ]; then
        echo "[*] Elevating with sudo to access ${DEV_PATH}..."
        exec sudo "$0" "$@"
    fi
fi

echo "[*] Flashing Qualcomm firmware, bootloader, LineageOS 23.2 super.img, and partition table..."
echo "[*] This completely wipes previous OS and installs pure LineageOS across the eMMC."

qdl --storage emmc --include "${SCRIPT_DIR}" prog_firehose_ddr.elf rawprogram0.xml patch0.xml

echo ""
echo "========================================================"
echo " [SUCCESS] Flashing complete!"
echo " 1. Remove the EDL jumper from the Arduino Uno Q."
echo " 2. Power cycle the board (unplug and replug USB-C)."
echo " 3. LineageOS 23.2 (Android 16) will boot cleanly!"
echo "========================================================"
"""
    with open(script_path, "w") as f:
        f.write(content)
    os.chmod(script_path, 0o755)
    print(f"[+] Created executable {script_path}")


def main():
    parser = argparse.ArgumentParser(description="Package LineageOS 23.2 for Arduino Uno Q into a QDL package")
    parser.add_argument("--top", default=None, help="Path to Android build root directory")
    parser.add_argument("--out-dir", default=None, help="Target directory for QDL package")
    parser.add_argument("--desktop", action="store_true", help="Also place copy/symlink on Desktop/imola-android-qdl")
    parser.add_argument("--qcombin-dir", default=None, help="Path to qcombin/Agatti directory")
    parser.add_argument("--skip-super", action="store_true", help="Skip super.img processing (faster for testing)")
    parser.add_argument(
        "--cmdline",
        default=(
            "earlycon console=ttyMSM0,115200n8 init=/init "
            "clk_ignore_unused pd_ignore_unused "
            "androidboot.hardware=imola androidboot.boot_devices=soc@0/4744000.mmc "
            "androidboot.verifiedbootstate=orange androidboot.slot_suffix=_a "
            "androidboot.selinux=permissive efi=noruntime "
            "androidboot.serialno=imola0001 "
            "firmware_class.path=/vendor/firmware,/vendor/firmware/qcom "
            "printk.devkmsg=on loglevel=7"
        ),
        help="Kernel command line to embed in /boot.scr",
    )

    args = parser.parse_args()

    # Detect Android build root
    if args.top:
        top_dir = os.path.abspath(args.top)
    else:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        top_dir = os.path.abspath(os.path.join(script_dir, "../../../.."))

    product_out = os.path.join(top_dir, "out/target/product/imola")
    if not os.path.isdir(product_out):
        sys.exit(f"[-] ERROR: Product out directory not found: {product_out}\n    Please build the target first (m bootimage superimage).")

    # Detect Qcombin directory
    qcombin_candidates = [
        args.qcombin_dir,
        os.path.join(os.path.expanduser("~"), "Desktop/qcombin/Agatti"),
        os.path.join(top_dir, "vendor/arduino/imola/qcombin/Agatti"),
    ]
    qcombin_dir = None
    for cand in qcombin_candidates:
        if cand and os.path.isdir(cand) and os.path.isfile(os.path.join(cand, "prog_firehose_ddr.elf")):
            qcombin_dir = os.path.abspath(cand)
            break

    if not qcombin_dir:
        sys.exit("[-] ERROR: qcombin Agatti directory not found! Clone it or pass --qcombin-dir <path>")

    qcombin_board_dir = os.path.join(qcombin_dir, "arduino-uno-q")
    if not os.path.isdir(qcombin_board_dir):
        sys.exit(f"[-] ERROR: Missing {qcombin_board_dir}")

    # Output directory
    if args.out_dir:
        out_dir = os.path.abspath(args.out_dir)
    else:
        out_dir = os.path.join(product_out, "imola_qdl_package")

    os.makedirs(out_dir, exist_ok=True)
    print(f"========================================================")
    print(f" Packaging LineageOS 23.2 QDL Bundle for Arduino Uno Q")
    print(f" Top Dir:      {top_dir}")
    print(f" Product Out:  {product_out}")
    print(f" Qcombin Dir:  {qcombin_dir}")
    print(f" Output Dir:   {out_dir}")
    print(f" Boot Method:  Native U-Boot boot.scr (booti)")
    print(f"========================================================")

    # Required Android artifacts
    kernel_path = os.path.join(product_out, "kernel")
    ramdisk_path = os.path.join(product_out, "ramdisk.img")
    dtb_path = os.path.join(product_out, "dtb.img")
    dtb_compiled = os.path.join(product_out, "obj/KERNEL_OBJ/arch/arm64/boot/dts/qcom/qrb2210-arduino-imola.dtb")
    if os.path.isfile(dtb_compiled):
        if not os.path.isfile(dtb_path) or os.path.getmtime(dtb_compiled) >= os.path.getmtime(dtb_path):
            shutil.copy2(dtb_compiled, dtb_path)
    super_path = os.path.join(product_out, "super.img")
    simg2img_bin = os.path.join(top_dir, "out/host/linux-x86/bin/simg2img")
    if not os.path.isfile(simg2img_bin):
        simg2img_bin = shutil.which("simg2img")

    for fpath in [kernel_path, ramdisk_path, dtb_path]:
        if not os.path.isfile(fpath):
            sys.exit(f"[-] ERROR: Missing required Android artifact: {fpath}")

    # 1. Copy Qualcomm Firmware binaries & programmer into out_dir
    print("[*] Copying Qualcomm firmware & EDL programmer from qcombin...")
    shutil.copy2(os.path.join(qcombin_dir, "prog_firehose_ddr.elf"), out_dir)
    shutil.copy2(os.path.join(qcombin_board_dir, "patch0.xml"), out_dir)

    for item in os.listdir(qcombin_board_dir):
        ext = os.path.splitext(item)[1].lower()
        if ext in [".elf", ".mbn", ".bin"] and not item.startswith("gpt_"):
            shutil.copy2(os.path.join(qcombin_board_dir, item), out_dir)

    # 2. Generate Android GPT partitions
    patch_gpt_tables(qcombin_board_dir, out_dir)

    # 3. Generate rawprogram0.xml
    generate_rawprogram(os.path.join(qcombin_board_dir, "rawprogram0.xml"), os.path.join(out_dir, "rawprogram0.xml"))

    # 4. Build efi.img
    efi_img_path = os.path.join(out_dir, "efi.img")
    build_efi_image(efi_img_path, kernel_path, ramdisk_path, dtb_path, args.cmdline)

    # 5. Process super.img
    if not args.skip_super:
        dst_super = os.path.join(out_dir, "super.img")
        process_super_image(super_path, dst_super, simg2img_bin)

    # 6. Generate flash.sh
    generate_flash_script(out_dir)

    # Desktop symlink/copy if requested
    if args.desktop:
        desktop_target = os.path.join(os.path.expanduser("~"), "Desktop/imola-android-qdl")
        if os.path.islink(desktop_target) or os.path.exists(desktop_target):
            if os.path.islink(desktop_target):
                os.unlink(desktop_target)
            else:
                shutil.rmtree(desktop_target)
        os.symlink(out_dir, desktop_target)
        print(f"[+] Linked package to Desktop: {desktop_target}")

    print("")
    print("========================================================")
    print(" [SUCCESS] QDL Android Package generated successfully!")
    print(f" Package Location: {out_dir}")
    print(" To flash to Arduino Uno Q in EDL mode:")
    print(f"   cd {out_dir}")
    print("   ./flash.sh")
    print("========================================================")


if __name__ == "__main__":
    main()
