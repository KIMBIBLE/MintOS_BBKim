# environment

* OS : ubuntu 16.04
* Kernel : 4.10.0-42-generic
* CC : gcc (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609

# package

* binutils bison flex libiconv libtool make patchutils libgmp-dev libmpfr-dev gcc-multilib

* more details to install libiconv in ubuntu

```
# wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.11.tar.gz
# tar -zxvf libiconv-*.tar.gz
# cd libiconv-*
# ./configure --prefix=/usr/local/libiconv
# make
# sudo make install
```
 
