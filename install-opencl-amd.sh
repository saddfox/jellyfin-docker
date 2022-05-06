#!/bin/bash
# Original script by @kytulendu https://gist.github.com/kytulendu/3351b5d0b4f947e19df36b1ea3c95cbe
#
# This version is slimmed down to only install legacy (orca) OpenCL 64-bit, ROCm and vulkan
# Intended for polaris (gfx8), tested on RX550. 
# Tested working on Ubuntu 22.04
# For other configurations please consult the original script
# Additional useful sources: https://gitlab.com/BCMM/amdgpu-opencl-on-debian

prefix='amdgpu-pro'

# amdgpu-pro package version
major='21'
minor='20'
build='1271047'
system='ubuntu-20.04'

# libdrm-amdgpu-amdgpu1 version
libdrmver='2.4.100'
libhsa_ver='1.3.0'

shared64="/opt/amdgpu-pro/lib/x86_64-linux-gnu"
ids="/opt/amdgpu/share/libdrm"

# make sure we’re running with root permissions.
if [ `whoami` != root ]; then
    echo Please run this script using sudo
    exit
fi

# download and extract drivers
echo Downloading drivers...
rm -r ${prefix}-${major}.${minor}-${build}-${system} &>/dev/null

if [ ! -f ./${prefix}-${major}.${minor}-${build}-${system}.tar.xz ]; then
    wget -q --referer https://www.amd.com/en/support/kb/release-notes/rn-amdgpu-unified-linux-21-10 https://drivers.amd.com/drivers/linux/${prefix}-${major}.${minor}-${build}-${system}.tar.xz
fi
tar xJf ${prefix}-${major}.${minor}-${build}-${system}.tar.xz

cd ${prefix}-${major}.${minor}-${build}-${system}

echo Extracting AMDGPU-PRO OpenCL driver files...
ar x "../${prefix}-${major}.${minor}-${build}-${system}/libdrm-amdgpu-amdgpu1_${libdrmver}-${build}_amd64.deb"
tar xJf data.tar.xz
ar x "../${prefix}-${major}.${minor}-${build}-${system}/libdrm-amdgpu-common_1.0.0-${build}_all.deb"
tar xJf data.tar.xz
ar x "../${prefix}-${major}.${minor}-${build}-${system}/opencl-orca-amdgpu-pro-icd_${major}.${minor}-${build}_amd64.deb"
tar xJf data.tar.xz

# Remove target directory, shouldn't be needed on ubuntu 22.04 at least
echo Remove target directory.
rm -r /opt/amdgpu &>/dev/null
rm -r /opt/amdgpu-pro &>/dev/null

# Create target directory
echo Create target directory.
mkdir -p ${ids}
mkdir -p ${shared64}

echo Patching and installing AMDGPU-PRO OpenCL driver...

# For some reasons this directory does not exist on some systems
if [ ! -f /etc/OpenCL/vendors ]; then
    echo Directory /etc/OpenCL/vendors does not exist, Creating it...
    mkdir -p /etc/OpenCL/vendors
else
    rm /etc/OpenCL/vendors/amdocl-orca64.icd
    rm /etc/OpenCL/vendors/amdocl-orca32.icd
    rm /etc/OpenCL/vendors/amdocl64.icd
fi
cp ./etc/OpenCL/vendors/*.icd /etc/OpenCL/vendors

cp ./opt/amdgpu/share/libdrm/amdgpu.ids /opt/amdgpu/share/libdrm

pushd ./opt/amdgpu/lib/x86_64-linux-gnu &>/dev/null
rm "libdrm_amdgpu.so.1"
mv "libdrm_amdgpu.so.1.0.0" "libdrm_amdpro.so.1.0.0"
ln -s "libdrm_amdpro.so.1.0.0" "libdrm_amdpro.so.1"
mv "libdrm_amdpro.so.1.0.0" "${shared64}"
mv "libdrm_amdpro.so.1" "${shared64}"
popd &>/dev/null

pushd ./opt/amdgpu-pro/lib/x86_64-linux-gnu &>/dev/null
sed -i "s|libdrm_amdgpu|libdrm_amdpro|g" libamdocl-orca64.so
mv "libamdocl-orca64.so" "${shared64}"
mv "libamdocl12cl64.so" "${shared64}"
popd &>/dev/null

echo "# AMDGPU-PRO OpenCL support" > zz_amdgpu-pro_x86_64.conf
echo "/opt/amdgpu-pro/lib/x86_64-linux-gnu" >> zz_amdgpu-pro_x86_64.conf
cp zz_amdgpu-pro_x86_64.conf /etc/ld.so.conf.d/
echo "# AMDGPU-PRO OpenCL support" > zz_amdgpu-pro_x86.conf
echo "/opt/amdgpu-pro/lib/i386-linux-gnu" >> zz_amdgpu-pro_x86.conf
cp zz_amdgpu-pro_x86.conf /etc/ld.so.conf.d/
ldconfig

echo "Finished!"

cd ..
echo "Cleaning up"
rm -r ${prefix}-${major}.${minor}-${build}-${system}

#just in case
rm /opt/amdgpu-pro/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 &>/dev/null
rm /opt/amdgpu-pro/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 &>/dev/null

echo Done.
