#!/bin/bash
convert -size 10x20 xc:red 10x20.png
convert -size 10x20 xc:red 10x20.gif

convert -size 10x20 xc:red -define tiff:endian=msb 10x20_msb.tiff
convert -size 10x20 xc:red -define tiff:endian=lsb 10x20_lsb.tiff

convert -size 10x20 xc:red 10x20.jpg
convert -size 10x20 xc:red 10x20_1.jpg; exiftool -Orientation=1 -n -q -overwrite_original 10x20_1.jpg
convert -size 10x20 xc:red 10x20_2.jpg; exiftool -Orientation=2 -n -q -overwrite_original 10x20_2.jpg
convert -size 10x20 xc:red 10x20_3.jpg; exiftool -Orientation=3 -n -q -overwrite_original 10x20_3.jpg
convert -size 10x20 xc:red 10x20_4.jpg; exiftool -Orientation=4 -n -q -overwrite_original 10x20_4.jpg
convert -size 20x10 xc:red 20x10_5.jpg; exiftool -Orientation=5 -n -q -overwrite_original 20x10_5.jpg
convert -size 20x10 xc:red 20x10_6.jpg; exiftool -Orientation=6 -n -q -overwrite_original 20x10_6.jpg
convert -size 20x10 xc:red 20x10_7.jpg; exiftool -Orientation=7 -n -q -overwrite_original 20x10_7.jpg
convert -size 20x10 xc:red 20x10_8.jpg; exiftool -Orientation=8 -n -q -overwrite_original 20x10_8.jpg
