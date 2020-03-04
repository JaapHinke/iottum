> Instructions are for macOS only

# FIRST TIME ONLY

### Make working folder

Open the **Terminal** application.

In the terminal write:
```
mkdir maps
cd maps
```
to create a working folder and use it.

This will be your working folder for working with the MapsIndoors API.
In the Finder, you can find it directly under your user folder.


### Save script

Download [`generate-iotspot-points.sh`](./generate-iotspot-points.sh) into the working folder.


### Save location types

Download [`iotspot-location-types.json`](./iotspot-location-types.json) into the working folder.


### Download jq tool

To use the script, you need the `jq` tool (a well-known JSON parser).
Download the latest binary from: [https://stedolan.github.io/jq/download/](https://stedolan.github.io/jq/download/) to your `Downloads` folder.

Then, in the Terminal, write:
```
mv ~/Downloads/jq-osx-amd64.dms jq
chmod a+x jq
```

This moves it to your working folder with the right name, and makes it executable.



# EACH DEPLOYMENT

### Open Terminal

Open the Terminal application.

In the terminal write:
```
cd maps
```
to use your working folder for maps.


### Get list with iotspots

In iotmin, go to the **Map** view.

Select the location about to be installed (eg, by doing a search).

Click **Sort Field** to get the right sorting (A-Z). This is the order in which the iotspots will positioned in the initial grid on the map.

Click **Export** and select **Export to CSV**.

This will download the file as `Map.csv` to the `Downloads` folder on your computer.

In the Terminal, write:
```
mv ~/Downloads/Map.csv .
```

This moves the `Maps.csv` file to the working folder.


### Run the script

In the Terminal, write:
```
generate-iotspot-points.sh
```

The following will happen:

* If needed, you will be prompted to **log in**. Use your CMS credentials. The terminal will remember the login for 24 hours.

* You will be prompted to **select the solution**.  
(If you previously selected a solution, you can just press Enter to continue.)

* If needed, you will be prompted to **generate "location types"** for iotspots.

* You will be prompted to **select the building**.  
(If you previously selected a building, you can just press Enter to continue.)

* Now you will be asked to **verify** if all the floors in the iotmin CSV have a matching ID in the MapsIndoors geodata. If not, first correct the map, or filter out the missing floor(s) when exporting from iotmin.

* If you continue, the script will generate the iotspot points to be created and list them.

* You will then be asked if you want to **upload** these points to the MapsIndoors API.

The Mapsindoors CMS should now show a **grid with the new points** on each floor, in the center of the floor.


### Aborting the script

You can stop the script at any time by pressing Ctrl-C, if necessary multiple times.


### Temporary files

The script will generate a number of temporary files in the working folder that you can ignore. They will be deleted the next time you run the script.


### Output files

If the script created iotspot location types, it will generate a `...-created-location-types.json` file with the IDs of the location types. This file is prefixed with the solution name and a timestamp.

If the script created iotspot points, it will generate a `...-created-points.json` file with the IDs of the location types. This file is prefixed with the solution name and a timestamp.

These files may be relevant, eg, if you at a later point need to delete the generated points.



# PLAYGROUND

As a playground, you can use the `IOTSpot Playground` that MapsIndoors created.

As test input you can use this `[Map.csv](./Map.csv)` file, instead of the output from the **Map** view in iotmin. It contains two iotspots: one for a room and one for a desk, both on the first floor.
