# How to create/modify CSV file
This document describes how to use the csv file provided with the repo. A user should be able to modify existing file to their like or create a new one for another airplne


## Filename
The file name of csv should match the ICAO code of the plane. If you don't know how to find your plane's ICAO. Please check the XPlane logs and look for something like this:
```
15:48:25 [Honeycomb Bravo v1.1.1]: INFO Aircraft identified as A321 with filename a319_StdDef.acf
```

`identified as XXXX` where `XXXX` is the ICAO. And in above example, you should create A321.csv and store it in `profiles` folder (where **A319.csv** is provided). 

>TIP: Simply copy the provided **A319.csv** and rename it is the easiest way to create a new profile.

>NOTE: Some developers don't name their ICAO properly so be careful to use real world ICAO

## Format
There are 6 columns in the CSV. Please don't modify/add/remove any of them
### name

### datarefs
### operators
### thresholds
### descriptions