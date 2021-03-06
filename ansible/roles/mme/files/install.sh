#!/bin/bash
#cd $(dirname ${BASH_SOURCE[0]})
#export C3PO_DIR=$PWD
echo "------------------------------------------------------------------------------"
echo " C3PO_DIR exported as $C3PO_DIR"
echo "------------------------------------------------------------------------------"

OSDIST=`lsb_release -is`
OSVER=`lsb_release -rs`

setup_env()
{
  # a. Check for OS and version dependencies
  case "$OSDIST" in
    Ubuntu)
      case "$OSVER" in
        14.04|16.04) echo "$OSDIST version $OSVER is supported." ;;
        *) echo "$OSDIST version $OSVER is unsupported." ; exit;;
      esac
      ;;
    *) echo "ERROR: Unsupported operating system distribution: $OSDIST"; exit;;
  esac

  echo
  echo "Checking network connectivity..."
  # b. Check for internet connections
  wget -T 3 -t 3 --spider http://www.google.com 2>/dev/null
  if [ "$?" != 0 ]; then
    while true; do
      read -p "No Internet connection. Are you behind a proxy (y/n)? " yn
      case $yn in
        [Yy]* ) $SETUP_PROXY ; return;;
        [Nn]* ) echo "Please check your internet connection..." ; exit;;
        * ) "Please answer yes or no.";;
      esac
    done
  fi

}
setup_env
################################################################################


get_agreement_download()
{
  echo
  echo "List of packages needed for C3PO build and installation:"
  echo "-------------------------------------------------------"

  case $OSDIST in
    Ubuntu)
      case $OSVER in
        14.04)
          echo "1. Cmake version 3.5.1"
          echo "2. libtool version 2.4.6"
          echo "3. Other libraries including :"
          echo "     gcc g++ libuv-dev libssl-dev automake libmemcached-dev memcached bison"
          echo "     flex libsctp-dev libgnutls-dev libgcrypt-dev libidn11-dev nettle-dev"
          ;;
        16.04)
          echo "gcc g++ make cmake libuv-dev libssl-dev autotools-dev libtool-bin"
          echo "m4 automake libmemcached-dev memcached cmake-curses-gui gcc bison"
          echo "flex libsctp-dev libgnutls-dev libgcrypt-dev libidn11-dev nettle-dev"
          ;;
        *) echo "$OSDIST version $OSVER is unsupported." ; exit;;
      esac
      ;;
    *) echo "ERROR: Unsupported operating system distribution: $OSDIST"; exit;;
  esac


}
get_agreement_download
install_cmake()
{
  file_name=".agree"
  if [ ! -e "$file_name" ]; then
    echo "Please choose option '2.Agree to download' first"
    return
  fi
  sudo apt-get -y purge cmake cmake-curses-gui
  sudo apt-get -y install g++ make autotools-dev m4 libncurses-dev
  pushd modules
  rm -rf cmake-3.5.1
  rm -rf cmake-3.5.1.tar.gz
  wget https://cmake.org/files/v3.5/cmake-3.5.1.tar.gz
  tar -xvf cmake-3.5.1.tar.gz
  cd cmake-3.5.1
  ./bootstrap && make -j4 && sudo make install
  popd
  echo "CMake compilation has been done" >> /tmp/build_result
}
install_cmake
install_libtool()
{
  pushd modules
  rm -rf libtool-2.4.6
  rm -rf libtool-2.4.6.tar.gz
  wget http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz
  tar -xvf libtool-2.4.6.tar.gz
  cd libtool-2.4.6
  ./configure && make && sudo make install
  popd
 echo "Libtool compilation has been done" >> /tmp/build_result
}
install_libtool
install_libs()
{
  echo "Install packages needed to build and run the C3PO components..."
  sudo apt-get update > /dev/null
  case $OSDIST in
    Ubuntu)
      case "$OSVER" in
        14.04) sudo apt-get -y install libuv-dev libssl-dev automake libmemcached-dev memcached gcc bison flex libsctp-dev libgnutls-dev libgcrypt-dev libidn11-dev nettle-dev ;;
        16.04) sudo apt-get -y install g++ make cmake libuv-dev libssl-dev autotools-dev libtool-bin m4 automake libmemcached-dev memcached cmake-curses-gui gcc bison flex libsctp-dev libgnutls-dev libgcrypt-dev libidn11-dev nettle-dev ;;
        *) echo "$OSDIST version $OSVER is unsupported." ; exit;;
      esac
      ;;
    *) echo "ERROR: Unsupported operating system distribution: $OSDIST"; exit;;
  esac
 echo "Lib installation has been done" >> /tmp/build_result

}
install_libs
################################################################################


init_submodules()
{
  git submodule init
  git submodule update
  build_freeDiameter
  build_c_ares
  build_cpp_driver
  build_pistache
  sudo ldconfig

}
#init_submodules
build_freeDiameter()
{
  pushd modules/freeDiameter
  rm -rf build
  mkdir -p build
  cd build
  cmake ..
  awk '{if (/^DISABLE_SCTP/) gsub(/OFF/, "ON"); print}' CMakeCache.txt > tmp && mv tmp CMakeCache.txt
  make
  sudo make install
  popd
 echo "FreeDiameter compilation has been done" >> /tmp/build_result

}
build_freeDiameter
build_c_ares()
{
  pushd modules/c-ares
  ./buildconf
  ./configure
  make
  sudo make install
  popd
 echo "c-ares compilation has been done" >> /tmp/build_result

}
build_c_areas
build_cpp_driver()
{
  pushd modules/cpp-driver
  rm -rf build
  mkdir -p build
  cd build
  cmake ..
  make
  sudo make install
  popd
 echo "cpp-driver compilation has been done" >> /tmp/build_result

}
build_cpp_driver
build_pistache()
{
  pushd modules/pistache
  rm -rf build
  mkdir -p build
  cd build
  cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ..
  make
  sudo make install
  popd
 echo "pistache compilation has been done" >> /tmp/build_result

}
build_pistache
################################################################################

build_c3po()
{
  make clean
  make
 echo "c3po build has been done" >> /tmp/build_result

}
build_c3po

