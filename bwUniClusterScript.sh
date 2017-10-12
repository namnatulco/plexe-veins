# This script executes the sims on the BwUniCluster.

#fresh clones
cd
rm -rf plexe_veins
rm -rf plexe_sumo
git clone plexe_veins.git plexe_veins
git clone plexe_sumo.git plexe_sumo

#compile sumo
cd plexe_sumo

#fetch and compile sumo dependencies
wget 'http://ftp.fox-toolkit.org/pub/fox-1.6.53.tar.gz'
tar xzf fox-1.6.53.tar.gz

wget 'http://download.osgeo.org/gdal/gdal-1.9.2.tar.gz'
tar xzf gdal-1.9.2.tar.gz

wget 'http://download.osgeo.org/proj/proj-4.6.0.tar.gz'
tar xzf proj-4.6.0.tar.gz

wget 'http://www-eu.apache.org/dist//xerces/c/3/sources/xerces-c-3.1.4.tar.gz'
if [ $? -ne 0 ]; then
  echo "error, downloading Xerces-C libs failed, probably there is a new version (old versions are not served here)"
  exit 1
fi
tar xzf xerces-c-3.1.4.tar.gz

export SUMOROOT="`pwd`/sumo"

export FOXROOT="`pwd`/fox-1.6.53"
export GDALROOT="`pwd`/gdal-1.9.2"
export PROJROOT="`pwd`/proj-4.6.0"
export XERCESCROOT="`pwd`/xerces-c-3.1.4"

cd "$XERCESCROOT"
./configure --prefix="$XERCESCROOT" && make && make install

cd "$FOXROOT"
./configure --prefix="$FOXROOT" && make -j install

#NOTE: GDAL's build process is not compatible with make -j
#NOTE: GDAL's dependency, jasper-devel, requires C++11 in the version running on the cluster
#      see https://bugzilla.redhat.com/show_bug.cgi?id=1455287
cd "$GDALROOT"
CXXFLAGS="${CXXFLAGS} -std=c++11" ./configure --prefix="$GDALROOT" --with-xerces="$XERCESCROOT" && make install

cd "$PROJROOT"
./configure --prefix="$PROJROOT" && make -j install

git checkout plexe-2.0
cd "$SUMOROOT"
make -f Makefile.cvs
./configure --with-fox-config=$FOXROOT/bin/fox-config --with-proj-gdal=$PROJROOT --with-gdal-config=$GDALROOT/bin/gdal-config --with-xerces=$XERCESCROOT
make -j

#compile veins
cd plexe_veins
./configure
make -j

#make execution-ready, check OMNET version
export SUMO_BIN="${SUMO_HOME}/bin"
export OMNETPP_BIN="${HOME}/omnet/omnetpp-5.1.1/bin"
export PATH="${PATH}:${SUMO_BIN}:${OMNETPP_BIN}"

#execution-ready versions (keep others for debugging)
cd
cp -r plexe_veins plexe_veins_run
cp -r plexe_sumo plexe_sumo_run
