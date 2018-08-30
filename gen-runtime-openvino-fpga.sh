#!/bin/sh

# this script will generate openvino runtime from openvino toolkit

YEAR=2018
VER=3
REV=343
YVR=${YEAR}.${VER}.${REV}
RYR=${REV}-${YEAR}.0-${REV}

# extract rpm files
#echo -n extract rpm files ...
#tar zxf l_openvino_toolkit_fpga_p_${YVR}.tgz l_openvino_toolkit_fpga_p_${YVR}/rpm --strip-components 1
#echo OK

ROOT=`pwd`

# define rootfs structure
USRBIN=rootfs/usr/bin
USRLIB=rootfs/usr/lib
LIB64=rootfs/lib64
SYSCONF=rootfs/etc
UDEVRULESD=${SYSCONF}/udev/rules.d
LDCONFD=${SYSCONF}/ld.so.conf.d
OPENVINO_CONF=${SYSCONF}/ld.so.conf.d/openvino.conf
OPENCLCONFD=${SYSCONF}/OpenCL/vendors
OPENVINO_LIB=rootfs/usr/lib/openvino/lib
OPENVINO_EXT=rootfs/usr/lib/openvino/external
OPENVINO_LIC=rootfs/usr/lib/openvino/licensing
OPENVINO_PYTHON=rootfs/usr/lib/openvino/python
OPENCV=rootfs/usr/lib/opencv
OPENCL=rootfs/usr/lib/opencl
OPENVX=rootfs/usr/lib/openvx
OPENVINO_RUNTIME_TGZ=openvino-runtime.tgz

# set up rootfs structure
echo -n set up rootfs structure ...
mkdir -p ${OPENVINO_LIB} ${OPENVINO_EXT} ${OPENVINO_LIC} ${OPENVINO_PYTHON} ${OPENCV} ${OPENCL} ${OPENVX} ${USRBIN} ${SYSCONF} ${UDEVRULESD} ${LDCONFD} ${OPENCLCONFD}
echo OK

# license
cp -a ./licensing/* ${OPENVINO_LIC}

# openvino IE
echo -n install openvino IE libs ...
rpm2cpio rpm/intel-cv-sdk-full-l-inference-engine-${RYR}.noarch.rpm | cpio -id ./opt/intel/computer_vision_sdk_fpga_${YVR}/deployment_tools/inference_engine/lib/ubuntu_16.04/intel64/* ./opt/intel/computer_vision_sdk_fpga_${YVR}/deployment_tools/inference_engine/external/* ./opt/intel/computer_vision_sdk_fpga_${YVR}/python/*
mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/deployment_tools/inference_engine/lib/ubuntu_16.04/intel64/* ${OPENVINO_LIB}
mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/deployment_tools/inference_engine/external/97-usbboot.rules ${UDEVRULESD}
mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/deployment_tools/inference_engine/external/* ${OPENVINO_EXT}
if [ ${VER} = 2 ]; then
    mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/python/* ${OPENVINO_PYTHON}
elif [ ${VER} = 3 ]; then
# yocto refuses to accept more python versions dependancy
    mkdir -p ${OPENVINO_PYTHON}/python2.7
    mkdir -p ${OPENVINO_PYTHON}/python3.5
    mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/python/python2.7/ubuntu16/* ${OPENVINO_PYTHON}/python2.7
    mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/python/python3.5/ubuntu16/* ${OPENVINO_PYTHON}/python3.5
fi
echo OK

# opencv
echo -n install opencv libs ...
rpm2cpio rpm/intel-cv-sdk-full-l-ocv-yocto-${RYR}.noarch.rpm | cpio -id ./opt/intel/computer_vision_sdk_fpga_${YVR}/opencv/lib/*
mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/opencv/lib/* ${OPENCV}
echo OK

# openvx
echo -n install openvx libs ...
rpm2cpio rpm/intel-cv-sdk-full-l-ovx-rt-yocto-${RYR}.noarch.rpm | cpio -id ./opt/intel/computer_vision_sdk_fpga_${YVR}/openvx/lib/*
mv ./opt/intel/computer_vision_sdk_fpga_${YVR}/openvx/lib/* ${OPENVX}
echo OK

# ipu firmware
echo -n install ipu firmware for yocto ...
rpm2cpio rpm/intel-cv-sdk-full-l-ipu-firmware-yocto-${RYR}.noarch.rpm | cpio -id
cd rootfs
rpm2cpio ../opt/intel/computer_vision_sdk_fpga_${YVR}/l_ipu_firmware_yocto/ipu4fw-cvsdk-r12018-20170225.rpm | cpio -id
rpm2cpio ../opt/intel/computer_vision_sdk_fpga_${YVR}/l_ipu_firmware_yocto/ipucompute-1.0.3-2018r1.x86_64.rpm | cpio -id
cd ..
echo OK

# fpga
echo -n install FPGA necessities ...
rpm2cpio rpm/intel-cv-sdk-full-l-opencl-rte-${RYR}.noarch.rpm | cpio -id
mv ./aoclrte.run ${USRBIN}
if [ ${VER} = 2 ]; then
    AOCL_PACK=aocl-pro-rte-17.1.2-304.x86_64.rpm
elif [ ${VER} = 3 ]; then
    AOCL_PACK=aocl-pro-rte-17.1.1-273p.x86_64.rpm
fi
rpm2cpio rpm/${AOCL_PACK} | cpio -id
mv ./opt/altera ${USRLIB}
echo OK

# opencl
echo -n install opencl libs ...
if [ ${VER} = 2 ]; then
    OPENCL_PACK=intel-opencl_2018ww15-010713_amd64.deb
elif [ ${VER} = 3 ]; then
    OPENCL_PACK=intel-opencl_18.28.11080_amd64.deb
fi
rpm2cpio rpm/intel-cv-sdk-full-gfx-install-${RYR}.noarch.rpm | cpio -id ./opt/intel/computer_vision_sdk_fpga_${YVR}/install_dependencies/${OPENCL_PACK}
ar -x ./opt/intel/computer_vision_sdk_fpga_${YVR}/install_dependencies/${OPENCL_PACK}
tar xf data.tar.xz
if [ ${VER} = 2 ]; then
mv ./opt/intel/opencl/* ${OPENCL}
elif [ ${VER} = 3 ]; then
mv ./usr/local/lib/* ${OPENCL}
fi
echo OK

# config files
echo -n install configuration files ...
echo "/usr/lib/openvino/lib" > ${OPENVINO_CONF}
echo "/usr/lib/openvino/external/mkltiny_lnx/lib" >> ${OPENVINO_CONF}
echo "/usr/lib/openvino/external/cldnn/lib" >> ${OPENVINO_CONF}
echo "/usr/lib/openvino/external/gna/lib" >> ${OPENVINO_CONF}
echo "/usr/lib/opencv" >> ${OPENVINO_CONF}
echo "/usr/lib/opencl" >> ${OPENVINO_CONF}
echo "/usr/lib/openvx" >> ${OPENVINO_CONF}
echo "/usr/lib/altera/aocl-pro-rte/host/linux64/lib" >> ${OPENVINO_CONF}
#echo "include ld.so.conf.d/openvino.conf" > ${SYSCONF}/ld.so.conf

echo "/usr/lib/opencl/libigdrcl.so" > ${OPENCLCONFD}/intel.icd
echo OK

# misc dependency
echo -n copy misc dependency files ...
cp -a depend/libformat_reader.so ${USRLIB}
cp -a depend/libOpenCL* ${OPENCL}
echo OK

# add missing lib64/ld-linux-x86-64.so.2
#echo -n add missing lib64/ld-linux-x86-64.so.2 ...
#ln -s /lib/ld-linux-x86-64.so.2 ${LIB64}/ld-linux-x86-64.so.2
#echo OK

# generate tarball for yocto
echo -n packaing ...
cd rootfs
tar zcf ${OPENVINO_RUNTIME_TGZ} *
echo OK
mv ${OPENVINO_RUNTIME_TGZ} ${ROOT}
echo The generated file is "${ROOT}/${OPENVINO_RUNTIME_TGZ}"
cd ${ROOT}

# cleanup
echo -n clean up ...
rm -rf rootfs opt etc usr control.tar.gz data.tar.xz debian-binary _gpgorigin
echo OK

echo finished
