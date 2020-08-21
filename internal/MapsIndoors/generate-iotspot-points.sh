###
### Script to generate MapsIndoors API input based on existing MapsIndoors API geodate and a iotmin export file.
###
### Copyright (C) 2020 iottum BV. All rights reserved.

# Run this script with:
# source ./generate-map-points.sh
# to keep environment variables' values after the script has run.


##### Constants #####

# Grid origin's position relative to building's "bounding box".
# Eg, 0.5 / 0.5 will put the origin in the center.

# TO DO: Verify:
# In the Eastern hemisphere, 0 is the left edge of the bounding box and 1 is the right edge.
# In the Western hemisphere, 0 is the right edge of the bounding box and 1 is the left edge.
GRID_RELATIVE_ORIGIN_HORIZONTAL=1.0

# In the Northern hemisphere, 0 is the bottom of the bounding box and 1 is the top.
# In the Southern hemisphere, 0 is the top of the bounding box and 1 is the bottom.
GRID_RELATIVE_ORIGIN_VERTICAL=0.5

# Distance in degrees between points on the initial grid.

# This is roughly one meter East-West (in North-West Europe) and 1.1 meters North-South.
# http://www.csgnetwork.com/degreelenllavcalc.html
# http://www.movable-type.co.uk/scripts/latlong.html

# For "top to bottom" rows in the grid: use negative distance for northern hemisphere, positive for southern hemisphere.
GRID_VERTICAL_SPACING=-0.000015 # degrees latitude (from north to south)
# For "left to right" columns in the grid: use positive distance.
GRID_HORIZONTAL_SPACING=0.000015 # degrees longitude (from west to east)


# Suffix to add to name for rooms.

ROOM_NAME_SUFFIX=" (Meeting Room)"



#### Location types #####





##### Used files #####

# Exported workplaces list from Map view in iotmin (or later: from Control Center).

IOTSPOT_WORKPLACES_FILE=Map.csv

# Fixed input.

IOTSPOT_LOCATION_TYPES_FILE=iotspot-location-types.json


# Temporary (intermediate) files, created by this script.

# Augmented version with index number added, used to calculate position on initial grid.
IOTSPOT_NUMBERED_WORKPLACES_TMP_FILE=Map-numbered-TMP.csv

# Augmented version with properties set in correct language(s) as needed by the selected solution.
IOTSPOT_LOCATION_TYPES_TMP_FILE=iotspot-location-types-TMP.json

# Full geodata file for selected solution.
MAPSINDOORS_GEODATA_TMP_FILE=geodata-TMP.json

# The new points to be created for the selected solution.
MAPSINDOORS_POINTS_INPUT_FILE=points-input.json


# Output files

# These files names will be prefixed with the solution name and a timestamp for the eventual file name.
# Note: "display type" is the API term, "location type" is the CMS term.

# The ids of the created location types (if any).
MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE=created-location-types.json

# The ids of the created points (if any).
MAPSINDOORS_CREATED_POINTS_IDS_FILE=created-points-ids.json



##### Clean-up #####

# Remove any old temporary files.

rm -f $IOTSPOT_NUMBERED_WORKPLACES_TMP_FILE
rm -f $IOTSPOT_LOCATION_TYPES_TMP_FILE
rm -f $MAPSINDOORS_GEODATA_TMP_FILE
rm -f $MAPSINDOORS_POINTS_INPUT_FILE



##### Allow jq to run from current folder #####

# In order to allow users to run jq from their current folder, add the current folder to the path.

PATH=$(pwd):$PATH



##### Pre-Processing #####

# Use awk to add an "index" at the beginning of each line. This is used later on to generate the coordinates for the points to be created, so they are positioned in an orderly grid in the center of the floor.
# This index is reset for each floor, since each floor will have its own grid.


# Explanation:
# -F is field separator
# NR>1 condition skips first line with headers in CSV
# print creates a comma separated file with the required fields from the iotmin export CSV:


# Columns 1 and 2 in the CSV file are dropped, and replaced by the calculated row and column.
# Columns 3-14 are copied as is (even though not all columns are used later). The remaining columns are not used.
# 3=Floor, 4 not used, 5=Zone Id, 6=Zone, 7=Cluster Id, 8=Seqno, 9=Workplace Id, 10=Workplace Code, 11=Category, 13 not used 12=Workplace Type, 14=Name, remainder not used 
# The "dummy" column's only purpose is to align column numbering between awk processing (here) and jq processing (further below). See comments further below.
# Workplace Code is used as "external id" in Maps (and is also device identifier)
# Category is 'S' (desk) or 'R' (room)
# Name is the iotspot image name
# Workplace Type is used as the description

# TO DO: Full "title capitalization" of name. First later capitalization is done as follows:
# ( toupper( substr( $14, 1, 1 ) ) substr( $14, 2 ) )

# Grid building logic:
# Restart row at 0 for each floor.
# Restart column at 0 for each zone.
# Within the same row (=zone), add use 1.4 spacing instead of 1.

# TO DO: Check this work correctly for multiple floors.

# Note: The last dummy value is a workaround that is needed because the jq parsing is done in a simple manner with '","' as the separator. Otherwise the last (now penultimate) field is not parsed correcty.

awk -F"\",\"" 'NR>1 {
    row = ($3 != prev_floor) ? 0 : row;
    row = ($5 != prev_zone_id) ? row + 1 : row;
    column = ($5 != prev_zone_id) ? 0 : column;
    column = (($5 == prev_zone_id) && ($7 != prev_cluster_id)) ? column + 1.4 : column + 1;
    row = (column > 21) ? row + 1 : row;
    column = (column > 21) ? 1 : column;
    print "\"dummy\",\"" row "\",\"" column "\",\"" $3 "\",\"" $4 "\"\",\"" $5 "\",\"" $6 "\",\"" $7 "\",\"" $8 "\",\"" $9 "\",\"" $10 "\",\"" $11 "\",\"" $12 "\",\"" $13 "\",\"" $14 "\",\"" dummy "\"";
    prev_floor = $3;
    prev_zone_id = $5;
    prev_cluster_id = $7
}' $IOTSPOT_WORKPLACES_FILE > $IOTSPOT_NUMBERED_WORKPLACES_TMP_FILE



##### Authorization #####

echo

# Check if access token, if available, has expired.

if [ $ACCESS_TOKEN ] ;then
    # Assuming that, if ACCESS_TOKEN is set, then ACCESS_TOKEN_EXPIRES is set as well.
    if [[ "$ACCESS_TOKEN_EXPIRES" < "$(date '+%Y-%m-%d %H:%M:%S')" ]] ;then
        echo "Previously received access token expired on: $ACCESS_TOKEN_EXPIRES, please log in again."
        echo

        # Delete existing ACCESS_TOKEN since it is expired. 
        unset ACCESS_TOKEN
    # else
        # echo "Access token not yet expired, expires: $ACCESS_TOKEN_EXPIRES"
    fi
fi


if [ $ACCESS_TOKEN ] ;then
    echo "Using previously received access token, expires: $ACCESS_TOKEN_EXPIRES"
else
    echo "Request access token from MapsIndoors CMS ..."

    # zsh uses '?' prefix instead of '-p'
    # read -p 'username: ' MAPSINDOORS_USERNAME
    read '?username: ' MAPSINDOORS_USERNAME
    read -s '?password: ' MAPSINDOORS_PASSWORD

    # Get access token response and parse.
    RESPONSE=$(curl -# --request POST \
    --data "grant_type=password&client_id=client&username=$MAPSINDOORS_USERNAME&password=$MAPSINDOORS_PASSWORD" \
    https://auth.mapsindoors.com/connect/token)

    export ACCESS_TOKEN=$(echo $RESPONSE  | jq -r .access_token)

    # Calculate when access token expires.
    EXPIRES_IN=$(echo $RESPONSE  | jq -r .expires_in)
    export ACCESS_TOKEN_EXPIRES=$(date -v+$(echo $EXPIRES_IN)S '+%Y-%m-%d %H:%M:%S')

    echo
    echo ... received access token, expires: $ACCESS_TOKEN_EXPIRES 
fi



##### Selecting the solution #####

echo
echo Getting available solutions from MapsIndoors...

SOLUTIONS=$(curl -# -X GET "https://integration.mapsindoors.com/api/dataset" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")
echo $SOLUTIONS | jq -c '.[] | { id, name }'


# Prompt user to select datasetId.
echo
echo "IMPORTANT: If the solution uses an API Key or an Extended App Security key (see CMS), then use that instead of the 'id'"
echo "Copy & paste 'id' for the solution below, then press Enter:"
if [ $DATASET_ID ] ; then
    # Parse solution name.
    SOLUTION_NAME=$(echo $SOLUTIONS | jq -r '.[] | select(.id=="'$DATASET_ID'") | .name')

    if [ "$SOLUTION_NAME" ] ; then
        echo "To keep current selection: $DATASET_ID ($SOLUTION_NAME) just press Enter."
    else

        # TO DO: Code duplicate, used again below. Consolidate?
        # In case an app key was used instead of a selection from the list, the dataset details need to be obtained using the key.
        # (Therefore not reusing the dataset data obtained in the previous call for all datasets.)
        SOLUTION=$(curl -# -X GET "https://integration.mapsindoors.com/$DATASET_ID/api/dataset" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")

        # Parse solution name.
        SOLUTION_NAME=$(echo $SOLUTION | jq -r '.name')

        if [ "$SOLUTION_NAME" ] ; then
            echo "To keep current selection: $DATASET_ID ($SOLUTION_NAME) just press Enter."
        else
            echo "(Note: Previously selected dataset with id/key: $DATASET_ID can no longer be found.)"
        fi
    fi
fi

# Read user input (will be available in REPLY variable).
read

# Use the input. If there is no reply, keep using existing DATASET_ID.
export DATASET_ID=${REPLY:-$DATASET_ID}



# In case an app key was used instead of a selection from the list, the dataset details need to be obtained using the key.
# (Therefore not reusing the dataset data obtained in the previous call for all datasets.)
SOLUTION=$(curl -# -X GET "https://integration.mapsindoors.com/$DATASET_ID/api/dataset" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")

# Parse solution name.
SOLUTION_NAME=$(echo $SOLUTION | jq -r '.name')
echo Selected solution: $SOLUTION_NAME



##### Determine languages needed in input for API #####

# TO DO: Warn if more than 3 languages are used, the script does not handle that.

# Get languages used for this solution.

LANGUAGES=$(echo $SOLUTION | jq -r '.availableLanguages')
echo Solution languages: $LANGUAGES

# Determine languages in script output (= API input).

# Assumption is that there will be at least 1 language.
LANG_1=$(echo $SOLUTION | jq -r '.availableLanguages | .[0]')

LANG_2=$(echo $SOLUTION | jq -r '.availableLanguages | .[1]')
# If there is no second language, then default LANG_2 to same as LANG_1.
# In the code below generating the points JSON it looks like it will then generate two identical entries but since they are identical, only one is actually generated.
if [ "$LANG_2" = "null" ] ;then
    LANG_2=$LANG_1
fi

LANG_3=$(echo $SOLUTION | jq -r '.availableLanguages | .[2]')
# If there is no third language, then default LANG_3 to same as LANG_1.
# In the code below generating the points JSON it looks like it will then generate two identical entries but since they are identical, only one is actually generated.
if [ "$LANG_3" = "null" ] ;then
    LANG_3=$LANG_1
fi



##### Getting/creating iotspot "location types" #####

echo
echo "Getting available \"location types\" for solution with id: $DATASET_ID ($SOLUTION_NAME) from MapsIndoors ..."

echo
DISPLAY_TYPES=$(curl -# -X GET "https://integration.mapsindoors.com/$DATASET_ID/api/displaytypes" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN")

echo $DISPLAY_TYPES | jq -c '.[] | { id, name }'
echo

# Checking if iotspot location types (displayTypes) are defined already.

DISPLAY_TYPE_ID_DESK=$(echo $DISPLAY_TYPES | jq '.[] | select(.name=="iotspot (desk)") | .id')
DISPLAY_TYPE_ID_ROOM=$(echo $DISPLAY_TYPES | jq '.[] | select(.name=="iotspot (room)") | .id')

if [ $DISPLAY_TYPE_ID_DESK ] && [ $DISPLAY_TYPE_ID_ROOM ] ;then

    echo "Using existing iotspot location types with ids: $DISPLAY_TYPE_ID_DESK and $DISPLAY_TYPE_ID_ROOM"
    echo

else

    echo "No iotspot location types found."
    read "?Continue to create the two location types for iotspot points (y/N)? "

    if [ "$REPLY" = "y" ] ;then

        # Use jq to parse the JSON "base" file, but instead of using the properties attributes "as is", reassign the English name and description to whatever languages the solutions uses (up to 3).
        # If LANG_1, LANG_2, and/or LANG_3 overlap, then only a single attribute will be generated for each language.
        # TO DO: Provide actual translations instead of just copying the English name.

        export LOCATION_TYPES=$(jq '[.[] | {
        name,
        displayRules,
        propertyTemplates,
        "properties": {
            "name@'$LANG_1'": .properties["name@en"],
            "name@'$LANG_3'": .properties["name@en"],
            "name@'$LANG_2'": .properties["name@en"],
            "description@'$LANG_1'": .properties["description@en"],
            "description@'$LANG_2'": .properties["description@en"],
            "description@'$LANG_3'": .properties["description@en"]
        }
        }]' $IOTSPOT_LOCATION_TYPES_FILE > $IOTSPOT_LOCATION_TYPES_TMP_FILE)

        echo "Location types to be created:"
        jq . $IOTSPOT_LOCATION_TYPES_TMP_FILE

        echo
        echo "Uploading location types to MapsIndoors ..."
        curl -# -X POST "https://integration.mapsindoors.com/$DATASET_ID/api/displaytypes" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d @$IOTSPOT_LOCATION_TYPES_TMP_FILE > $MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE

        echo "MapsIndoors response (returned ids of created location types, if successful):"
        cat $MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE | jq .


        # Determine display type for rooms and seats.

        echo Parsing IDs ...
        RESULT=$(cat $MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE | jq '.[0]')
        if [ $RESULT ] ;then
            export DISPLAY_TYPE_ID_DESK=$RESULT
        fi

        RESULT=$(cat $MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE | jq '.[1]')
        if [ $RESULT ] ;then
            export DISPLAY_TYPE_ID_ROOM=$RESULT
        fi

        echo "- location type id for iotspot (desk): $DISPLAY_TYPE_ID_DESK"
        echo "- location type id for iotspot (room): $DISPLAY_TYPE_ID_ROOM"

        # Rename the file with ids of the created location types ids file to include solution name and timestamp.

        DATE=$(date '+%Y%m%d-%H%M%S')

        # Location types output from MapsIndoors
        NEW_FILE="$SOLUTION_NAME-$DATE-$MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE"
        # cp "$MAPSINDOORS_POINTS_INPUT_FILE" "$NEW_FILE"
        # Using jq to format nicely.
        cat $MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE | jq . > "$NEW_FILE"
        rm -f "$MAPSINDOORS_CREATED_LOCATION_TYPES_IDS_FILE"
        echo "Saved MapsIndoors location types ids output in file: $NEW_FILE"


    else
        echo ... Canceled.
        return
    fi

fi



##### Selecting building #####

echo
echo "Getting buildings for solution with id: $DATASET_ID ($SOLUTION_NAME) from MapsIndoors ..."

curl -# -X GET "https://integration.mapsindoors.com/$DATASET_ID/api/geodata" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" | jq . > $MAPSINDOORS_GEODATA_TMP_FILE

jq -c '.[] | select(.baseType | contains("building")) | { id, name: .properties["name@'$LANG_1'"] }' $MAPSINDOORS_GEODATA_TMP_FILE


# Prompt user to select building

echo
echo "Copy & paste 'id' for the building, then press Enter"
if [ $BUILDING_ID ] ; then

    # Parse building name.
    BUILDING_NAME=$(jq -r '.[] | select(.id=="'$BUILDING_ID'") | .properties["name@'$LANG_1'"]' $MAPSINDOORS_GEODATA_TMP_FILE)

    if [ "$BUILDING_NAME" ] ; then
        echo "To keep current selection: $BUILDING_ID ('$BUILDING_NAME') just press Enter"
    else
        echo "Note: Previously selected building with id: $BUILDING_ID was not found in dataset with id: $DATASET_ID ($SOLUTION_NAME)"
        # Delete existing BUILDING_ID since it cannot be used within this solution. 
        unset BUILDING_ID
    fi

fi

# Read user input (will be available in REPLY variable).
read

# Use the input. If there is no reply, keep using existing BUILDING_ID.
export BUILDING_ID=${REPLY:-$BUILDING_ID}

# Parse building name.
BUILDING_NAME=$(jq -r '.[] | select(.id=="'$BUILDING_ID'") | .properties["name@'$LANG_1'"]' $MAPSINDOORS_GEODATA_TMP_FILE)
echo Selected building: $BUILDING_NAME



##### Verify floor mapping #####

# Check that the floors for the workplaces in the iotmin file have a corresponding matching floor in the MapsIndoors geodata.

# Create a JSON object mapping a floor name to the MapsIndoors ID and the floor's geospatial "bounding box".
# Floor 'name' should match the Floor field in Map.csv from iotmin.
# The bounding box will be used later to center the initial grid with iotspot point on each floor.

FLOOR_DATA=$(jq '[.[] | select(.parentId == "'$BUILDING_ID'") | select(.baseType | contains("floor")) | { (.baseTypeProperties.name): { id: .id, boundingbox: .geometry.bbox } }] | add' $MAPSINDOORS_GEODATA_TMP_FILE)
# echo $FLOOR_DATA


# Let user check if all floors are available in MapsIndoors.

echo

echo Verifying floors...
echo

echo "All floors found in $IOTSPOT_WORKPLACES_FILE:"
awk  -F"\",\""  'NR>1 { print "\"" $3 "\"" }' $IOTSPOT_WORKPLACES_FILE | sort | uniq
echo

echo "All floors found in MapsIndoors for selected building $BUILDING_ID ('$BUILDING_NAME'):"
# This is the same selection as used for FLOOR_DATA above, but easier to read.
jq '.[] | select(.parentId == "'$BUILDING_ID'") | select(.baseType | contains("floor")) | .baseTypeProperties.name' $MAPSINDOORS_GEODATA_TMP_FILE

# Read user input (will be available in REPLY variable).
echo  
read "?Do all floors found in $IOTSPOT_WORKPLACES_FILE have a corresponding floor in MapsIndoors (y/N)? "

if [ "$REPLY" = "${REPLY#[Yy]}" ] ;then
    echo ... Canceled.
    return
fi


##### Check if a START HERE point is defined.

# TO DO: Limit to selected building. Is a bit hard since the parent of a point is a floor, not a building. So would have to check all floors in the building.
# For now, we just look for the START HERE point.

# Delete any lingering old values
unset START_HERE_POINT_ID
unset START_HERE_LONGITUDE
unset START_HERE_LATITUDE

START_HERE_POINT_ID=$(jq -r '.[] | select(.baseType | contains("poi")) | select(.properties["name@'$LANG_1'"] | ascii_upcase == "START HERE") | .id' $MAPSINDOORS_GEODATA_TMP_FILE)

if [ $START_HERE_POINT_ID ] ; then

    START_HERE_LONGITUDE=$(jq -r '.[] | select(.baseType | contains("poi")) | select(.properties["name@'$LANG_1'"] | ascii_upcase == "START HERE") | .geometry.coordinates[0]' $MAPSINDOORS_GEODATA_TMP_FILE)
    START_HERE_LATITUDE=$(jq -r '.[] | select(.baseType | contains("poi")) | select(.properties["name@'$LANG_1'"] | ascii_upcase == "START HERE") | .geometry.coordinates[1]' $MAPSINDOORS_GEODATA_TMP_FILE)
    echo "Found grid origin based on 'START HERE' point, longitude: $START_HERE_LONGITUDE latitude: $START_HERE_LATITUDE, id: $START_HERE_POINT_ID"

    # Create ISO string data, to use in description allowing for easier cross reference to check-ins.
    ACTIVE_TO=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Hide the START HERE point by making it "active to" now.
    START_HERE_POINT_UPDATE="[
        {
            \"id\": \"$START_HERE_POINT_ID\",
        \"baseTypeProperties\": {
            \"activeto\": \"$ACTIVE_TO\"
            }
        }
    ]"

    echo "Uploading update to hide START HERE point to MapsIndoors in solution $DATASET_ID ($SOLUTION_NAME) ..."

    curl -# -X PUT "https://integration.mapsindoors.com/$DATASET_ID/api/geodata" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d "$START_HERE_POINT_UPDATE"

    echo
    read "?Continue with preparing the new points (y/N)? "

    if [ "$REPLY" = "${REPLY#[yY]}" ] ;then
        echo ... Canceled.
        return
    fi

fi


##### Generating new points input file #####

# This steps generates a JSON file with iotspot points, to be created in MapsIndoors with the API.

# This is done by jq parsing the CSV file, and generating JSON input, using the FLOOR_DATA generated above. This happens in a series of steps:

# The first few steps split the CSV file in lines and then process line by line.

# Then for each line:
# The columns in the CSV file are parsed into a $fields array.
# The various fields are assigned to local variables, eg $_floor_level.
# For some local variables (eg, determining the initial grid position) some calculations are done as part of this.
# Some of the local variables are only used for intermediate calculations, these start with an "_" like: $_floor_level.

# The rows and columns for the grid are calculated with awk, further above.

# The position of the grid (to the right of the map "bounding box") and vertically in the middle is done below in jq.
# This uses the GRID_RELATIVE_ORIGIN_HORIZONTAL and GRID_RELATIVE_ORIGIN_VERTICAL variables defined at the beginning of the script.
# TO DO: Make sure the bounding box interpretation is correct for western and southern hemispheres.

# The origin location for the grid can be overriden by defining a point on the map (any type of point, on any floor) with the name "START HERE".
# For more detail, see calculation of START_HERE_LONGITUDE and START_HERE_LATITUDE, above.

# Finally, most of the local variables are used to generate a 'point' element in the JSON output, resulting in a final JSON structure that can be used in the MapsIndoors API.
# Note: The _iotspot_start_grid value for each entry is for iotspot debugging only and will be ignored by the API.

# A few hacks were done to align the column numbering in the awk processing (above) and the jq processing (below).
# (Note: In awk, the first column is 1 and in jq, the first column is 0.)
# Field 0 is a dummy field.
# Fields 1 and 2 are calculated (with awk, above) grid coordinates (row/column). They replace two fields in the original CSV that are not used anyway.
# Other fields:
# 3=Floor, 4 not used, 5=Zone Id, 6=Zone, 7=Cluster Id, 8=Seqno, 9=Workplace Id, 10=Workplace Code, 11=Category, 13 not used 12=Workplace Type, 14=Name, remainder not used 

# jq is used to reverse the array so that the icons are placed with leftmost ones in the foreground. For some reason, this does not work for rows, as lower rows are always covering higher placed rows, regardless of when they were placed onto the map.

jq -Rsn --argjson floor_data "${FLOOR_DATA[@]}" '
    [inputs
    | . / "\n"
      | reverse
      | (.[]
      | select(length > 0) | . / "\",\"") as $fields
      | ($fields[1] | tonumber) as $grid_row
      | ($fields[2] | tonumber) as $grid_column
      | $fields[3] as $_floor_level
      | $floor_data[$_floor_level].id as $parentId
      | $floor_data[$_floor_level].boundingbox[0] as $_min_longitude
      | $floor_data[$_floor_level].boundingbox[1] as $_min_latitude
      | $floor_data[$_floor_level].boundingbox[2] as $_max_longitude
      | $floor_data[$_floor_level].boundingbox[3] as $_max_latitude
      | ($_min_longitude + '$GRID_RELATIVE_ORIGIN_HORIZONTAL' * ($_max_longitude - $_min_longitude)) as $_longitude_calculated
      | ($_min_latitude + '$GRID_RELATIVE_ORIGIN_VERTICAL' * ($_max_latitude - $_min_latitude)) as $_latitude_calculated
      | (if ("'$START_HERE_LONGITUDE'" != "") then ("'$START_HERE_LONGITUDE'" | tonumber) else $_longitude_calculated end) as $longitude
      | (if ("'$START_HERE_LATITUDE'" != "") then ("'$START_HERE_LATITUDE'" | tonumber) else $_latitude_calculated end) as $latitude
      | $fields[6] as $zone
      | $fields[9] as $workplace_id
      | $fields[10] as $workplace_code
      | $fields[11] as $_category
      | $fields[14] as $iotspot_name
      | (if ($_category == "R") then $iotspot_name + " (Meeting Room)" else $iotspot_name end) as $name
      | (if ($_category == "R") then '$DISPLAY_TYPE_ID_ROOM' else '$DISPLAY_TYPE_ID_DESK' end) as $displayTypeId
      | $fields[12] as $description
      | {
            "parentId": $parentId,
            "datasetId": "'$DATASET_ID'",
            "externalId": $workplace_code,
            "baseType": "poi",
            "displayTypeId": $displayTypeId,
            "geometry": {
                "coordinates": [
                    $longitude + $grid_column * '$GRID_HORIZONTAL_SPACING',
                    $latitude + $grid_row * '$GRID_VERTICAL_SPACING'
                ],                    
                "type": "Point"
            },
            "properties": {
                "name@'$LANG_1'": $name,
                "name@'$LANG_2'": $name,
                "name@'$LANG_3'": $name,
                "description@'$LANG_1'": ($description | sub("&amp;";"&")),
                "description@'$LANG_2'": ($description | sub("&amp;";"&")),
                "description@'$LANG_3'": ($description | sub("&amp;";"&")),
                "workplace id@'$LANG_1'": $workplace_id,
                "workplace id@'$LANG_2'": $workplace_id,
                "workplace id@'$LANG_3'": $workplace_id,
                "zone@'$LANG_1'": ($zone | sub("&amp;";"&")),
                "zone@'$LANG_2'": ($zone | sub("&amp;";"&")),
                "zone@'$LANG_3'": ($zone | sub("&amp;";"&"))
            },
            "_iotspot_start_grid": {
                "row": $grid_row,
                "column": $grid_column
            },
        }
    ]
' $IOTSPOT_NUMBERED_WORKPLACES_TMP_FILE > $MAPSINDOORS_POINTS_INPUT_FILE

echo
echo "Generated $MAPSINDOORS_POINTS_INPUT_FILE file with contents:"
# Use jq for nice formatting.
cat $MAPSINDOORS_POINTS_INPUT_FILE | jq .

COUNT=$(cat $MAPSINDOORS_POINTS_INPUT_FILE | jq '. | length')

##### Ask user to confirm upload of new points #####

echo
echo "Total of: $COUNT points will be added to building: $BUILDING_ID ('$BUILDING_NAME') in solution: $DATASET_ID ($SOLUTION_NAME)."

# Read user input (will be available in REPLY variable).
echo
read "?Upload the new points to MapsIndoors (y/N)? "

if [ "$REPLY" = "${REPLY#[yY]}" ] ;then
    echo ... Canceled.
    return
fi

echo
echo "Uploading points to MapsIndoors for building: $BUILDING_ID ('$BUILDING_NAME') in solution: $DATASET_ID ($SOLUTION_NAME) ..."

curl -# -X POST --http1.1  "https://integration.mapsindoors.com/$DATASET_ID/api/geodata" -H "accept: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d @$MAPSINDOORS_POINTS_INPUT_FILE > $MAPSINDOORS_CREATED_POINTS_IDS_FILE

echo
echo "MapsIndoors response (returned ids of created points, if successful):"
# Pipe result into jq for nice formatting.
cat $MAPSINDOORS_CREATED_POINTS_IDS_FILE | jq '.'

# Keep the input and output files for future reference.
# To do this, rename them to include the solution name and timestamp.

DATE=$(date '+%Y%m%d-%H%M%S')

# Exported CSV file from iotmin
# The original file is not removed to allow for reruns, if needed.
NEW_FILE="$SOLUTION_NAME-$DATE-$IOTSPOT_WORKPLACES_FILE"
cp "$IOTSPOT_WORKPLACES_FILE" "$NEW_FILE"
echo "Saved iotspot workplaces export in file: $NEW_FILE"

# Points input generated by script
NEW_FILE="$SOLUTION_NAME-$DATE-$MAPSINDOORS_POINTS_INPUT_FILE"
# cp "$MAPSINDOORS_POINTS_INPUT_FILE" "$NEW_FILE"
# Using jq to format nicely.
cat $MAPSINDOORS_POINTS_INPUT_FILE | jq . > "$NEW_FILE"
rm -f "$MAPSINDOORS_POINTS_INPUT_FILE"
echo "Saved MapsIndoors points input in file: $NEW_FILE"

# Points output from MapsIndoors
NEW_FILE="$SOLUTION_NAME-$DATE-$MAPSINDOORS_CREATED_POINTS_IDS_FILE"
# cp "$MAPSINDOORS_POINTS_INPUT_FILE" "$NEW_FILE"
# Using jq to format nicely.
cat $MAPSINDOORS_CREATED_POINTS_IDS_FILE | jq . > "$NEW_FILE"
rm -f "$MAPSINDOORS_CREATED_POINTS_IDS_FILE"
echo "Saved MapsIndoors points ids output in file: $NEW_FILE"



##### Other examples for parsing geodata #####

# floors
# jq '.[] | select(.baseType | contains("floor")) | { id, parentId, baseType, baseTypeProperties }' $MAPSINDOORS_GEODATA_TMP_FILE  
# echo

# all seats/rooms
# jq '.[] | select(.baseType | contains("poi")) | select(.anchor != null) |   { baseType, anchor, properties }' $MAPSINDOORS_GEODATA_TMP_FILE

# all seats
# jq '.[] | select(.baseType | contains("poi")) | select(.displayTypeId | contains("'$DISPLAY_TYPE_ID_ROOM'")) ' $MAPSINDOORS_GEODATA_TMP_FILE  

# points with coordinates
# jq '[.[] | select(.baseType | contains("poi")) | { name: .properties["name@'$LANG_1'"], coordinates: .geometry.coordinates, displayTypeId } ]' $MAPSINDOORS_GEODATA_TMP_FILE  


jq '[.[] | select(.baseType | contains("poi")) | select(.properties["name@'$LANG_1'"] | contains("START HERE")) | { name: .properties["name@'$LANG_1'"], coordinates: .geometry.coordinates, displayTypeId } ]' $MAPSINDOORS_GEODATA_TMP_FILE  


