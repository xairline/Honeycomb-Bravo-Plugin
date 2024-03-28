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
There are 6 columns in the CSV. Please don't modify/add/remove any of them (headers).

Each row represents a LED light on honeycomb bravo. See following details.

### name
This is binded to Honeycomb Bravo LEDs. You can not add or modify this. However, you may remove a row if you want to use XPlane default or simply don't know what to put. Note that most 3rd party planes use some of their own dataref instead of default ones. 

### datarefs
This is where you can define a dataref or multiple datarefs that the corresponding LED should react on. 

**IMPORT**: To use multiple datarefs, each dataref is separated by `;`. DO NOT USE `,`

### operators
This is simply how we should compare the dataref with threshold. you can use one of following:

```
>,<,>=,<=,==,~=
```

### thresholds
This is the thershold you are comparing to. Note that you should try NOT to compare to 0. This is because some datarefs are `float` which means 0 is not exactly 0 but something like 0.000000001. If you try to do something like `SOME_DATAREF > 0` it might be always true. What you want is `SOME_DATAREF > 0.001`

### descriptions
This field is simply left there for you to take notes/make comments

## How to test my new configuration

If you are changing the csv file, the best way to test it would be simply reload the lua script from XPlane menu. You don't have to reload XPlane.

Logs are in X Plane's `Log.txt`, attach that if you need any help