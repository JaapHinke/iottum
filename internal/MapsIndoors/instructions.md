# Script for creating iotspot points in MapsIndoors

> These instructions are for macOS only

## INTRODUCTION

The first section describes what files to download (only needed once).

The middle section explains how to run the downloaded script to create iotspoints "points" in MapsIndoors. You will need MapsIndoors credentials for CMS for this.

The final section describes a test playground and test input file.


## FIRST TIME ONLY

### Make working folder

Open the **Terminal** application.

In the terminal write:

    mkdir maps
    cd maps

to create a working folder and use it.

This will be your working folder for working with the MapsIndoors API.
In the Finder, you can find it directly under your user folder.


### Download jq tool

The script relies on the `jq` tool, a well-known JSON parser, to parse and generate geodata.
Download the latest 64-bit binary for OS X (macOS) from: [https://stedolan.github.io/jq/download/](https://stedolan.github.io/jq/download/) into the working folder (right-click and select `Download Linked File As...`).

Then, in the Terminal, write:

    mv jq-osx-amd64.dms jq
    chmod a+x jq

This gives it the right name and makes it executable.


### Save script

Download [`generate-iotspot-points.sh`](./generate-iotspot-points.sh) into the working folder (right-click and select `Download Linked File As...`).


### Save location types

Download [`iotspot-location-types.json`](./iotspot-location-types.json) into the working folder (right-click and select `Download Linked File As...`).



## EACH DEPLOYMENT

### Get list with iotspots

In iotmin, go to the [**Map**](https://app.iotspot.co/iotmin/workplace_zone.php?order%5B0%5D=asort_field) view.

Select the workplaces with iotspots that you want to add to the map (eg, by doing a search on location and floor).

If you used the link above the list is already sorted. If not, then click **Sort Field** to get the right sorting (A-Z), in the same order as the iotspots are presented in the app. This order will be used for the grid with new iotspots on the map.

Click **Export** and select **Export to CSV**.

This will download the file as `Map.csv` to the `Downloads` folder on your computer. Move it to your `maps` working folder.


### Run the script

Open the Terminal application, and write:

    cd maps
    source generate-iotspot-points.sh

to go to your working folder and run the script.

The script will then ask you to:

* if needed, **log in**. Use your CMS credentials. The terminal will remember the login for 24 hours.

* **select the solution** where you want to create the iotspot points.  
(If you want to use a previously selected solution again, you can just press Enter to continue.)

* if needed, **generate "location types"** for iotspots.

* **select the building** where you want to create the iotspot points.  
(If you want to use a previously selected building again, you can just press Enter to continue.)

* **verify** if all the floors found in the exported `Map.csv` file have a matching ID in the MapsIndoors geodata.  
If not, first correct the map, or filter out the missing floor(s) when exporting from iotmin.

* the script will then let you preview the iotspot points that will be created and ask you to confirm **uploading** them to the MapsIndoors API.

The Mapsindoors CMS should now show a **grid with the new points** on each floor, in the center of the floor.


### Stopping the script

You can stop the script at any time by pressing Ctrl-C, if necessary multiple times.


### Temporary files

The script will generate a number of temporary files in the working folder that you can ignore. They will be deleted the next time you run the script.


### Output files

If the script created iotspot location types, it will generate a `<solution name>-<date/time>-created-location-types.json` file with the IDs of the location types. This file is prefixed with the solution name and a timestamp.

If the script created iotspot points, it will generate a `<solution name>-<date/time>-created-points.json` file with the IDs of the location types. This file is prefixed with the solution name and a timestamp.

These files may be relevant, eg, if you at a later point need to delete the generated points.



## PLAYGROUND

As a playground, you can use the `IOTSpot Playground` that MapsIndoors created.

As test input, you can download this [`Map.csv`](./Map.csv) into the working folder (right-click and select `Download Linked File As...`). You can use this instead of the output from the **Map** view in iotmin. It contains two iotspots: one for a room and one for a desk, both on the first floor.
