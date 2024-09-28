#!/usr/bin/env bash

# DATECODE=$(/bin/date +%y%m%d-%H%M)


# example filenames from dadu-oneday
# 240922-1825.jpg
# 240922-1830.jpg
# 240922-1835.jpg
# 240922-1840.jpg
# 240922-1845.jpg
# 240922-1850.jpg
# 240922-1855.jpg
# 240922-1900.jpg
# 240922-1905.jpg
# 240922-1910.jpg
# 240922-1915.jpg
# 240922-1920.jpg
# 240922-1925.jpg
# 240922-1930.jpg
# 240922-1935.jpg
# 240922-1940.jpg
# 240922-1945.jpg
# 240922-1950.jpg
# 240922-1955.jpg
# 240922-2000.jpg
# 240922-2005.jpg
# 240922-2010.jpg
# 240922-2015.jpg
# 240922-2020.jpg
# 240922-2025.jpg
# 240922-2030.jpg
# 240922-2035.jpg
# 240922-2040.jpg
# 240922-2045.jpg
# 240922-2050.jpg
# 240922-2055.jpg
# 240922-2100.jpg
# 240922-2105.jpg
# 240922-2110.jpg
# 240922-2115.jpg
# 240922-2120.jpg
# 240922-2125.jpg
# 240922-2130.jpg
# 240922-2135.jpg
# 240922-2140.jpg
# 240922-2145.jpg
# 240922-2150.jpg
# 240922-2155.jpg
# 240922-2200.jpg
# 240922-2205.jpg
# 240922-2210.jpg
# 240922-2215.jpg
# 240922-2220.jpg
# 240922-2225.jpg
# 240922-2230.jpg
# 240922-2235.jpg
# 240922-2240.jpg
# 240922-2245.jpg
# 240922-2250.jpg
# 240922-2255.jpg
# 240922-2300.jpg
# 240922-2305.jpg
# 240922-2310.jpg
# 240922-2315.jpg
# 240922-2320.jpg
# 240922-2325.jpg
# 240922-2330.jpg
# 240922-2335.jpg
# 240922-2340.jpg
# 240922-2345.jpg
# 240922-2350.jpg
# 240922-2355.jpg

  DATE=$(echo $1 | cut -d'-' -f1)
  DAY=$(date -j -f "%d%m%y" $DATE +%u)

  if [ $DAY -eq 6 ] || [ $DAY -eq 7 ]; then
    echo "The file $1 is from a weekend."
  else
    echo "The file $1 is not from a weekend."
  fi



# copy all the files created between 7am and 5:30pm to dadu-oneday
# 7am = 0700
# 5:30pm = 1730
find /Volumes/Bomb19/dadu -type f -name "*-0[7-9]*.jpg" -exec cp {} /Volumes/Bomb19/dadu-processed \;
find /Volumes/Bomb19/dadu -type f -name "*-1[0-6]*.jpg" -exec cp {} /Volumes/Bomb19/dadu-processed \;
find /Volumes/Bomb19/dadu -type f -name "*-17[0-2]*.jpg" -exec cp {} /Volumes/Bomb19/dadu-processed \;
find /Volumes/Bomb19/dadu -type f -name "*-173[0-0]*.jpg" -exec cp {} /Volumes/Bomb19/dadu-processed \;

# Check if the file is from a weekend
find /Volumes/Bomb19/dadu-processed -type f -name "*.jpg" | while read file; do
  DATE=$(echo $(basename $file) | cut -d'-' -f1)
  DAY=$(date -j -f "%d%m%y" $DATE +%u)

  if [ $DAY -eq 6 ] || [ $DAY -eq 7 ]; then
    echo "The file /Volumes/Bomb19/dadu-processed/$file is from a weekend."
    rm /Volumes/Bomb19/dadu-processed/$file
  fi
done

exit 0