#!/bin/bash
# version 0.6
# reads the Phidget Bridge board or other scale boards and scales the output
# Updated to remove the percentage check, since that seems to cause a lot of bad values
# Now we just check for expected weights within range between 0 and 1500 lbs.

WEIGHTRUNDIR=/home/HiveControl/scripts/weight
# Get some variables from our central file
source /home/HiveControl/scripts/hiveconfig.inc
source /home/HiveControl/scripts/data/logger.inc

##### NEED TO FIX THIS ONE TO CHECK FOR A ZERO INTERCEPT


DATE=$(TZ=":$TIMEZONE" date '+%F %T')

if [[ -z "$HIVE_WEIGHT_INTERCEPT" ]] || ; then
	echo "Weight Intercept Not Set"
	loglocal "$DATE" WEIGHT ERROR "Please set Weight Zero Value in the Instruments page"
	HIVE_WEIGHT_INTERCEPT=1	
fi
if [[ -z $HIVE_WEIGHT_SLOPE ]]; then
	loglocal "$DATE" WEIGHT ERROR "Please set Weight Slope in the Instruments page"
	HIVE_WEIGHT_SLOPE=1
fi

if [ "$SCALETYPE" = "hx711" ]; then
	RAWWEIGHT=`$WEIGHTRUNDIR/hx711.sh`
elif [ "$SCALETYPE" = "phidget1046" ]; then
        RAWWEIGHT=`$WEIGHTRUNDIR/phidget1046.sh`
elif [ "$SCALETYPE" = "cpw200plus" ]; then
	RAWWEIGHT=`$WEIGHTRUNDIR/cpw200plus.sh`
else
	loglocal "$DATE" WEIGHT ERROR "No scale type specified"
	echo "0 0"
	exit
fi

if [[ -z $RAW ]]; then
	#statements
fi
# Test our values for expected range
ec
	RAW_MINTEST=$(echo "$RAWWEIGHT < 0" | bc)
    RAW_MAXTEST=$(echo "$RAWWEIGHT > 1500" | bc)

if [ $RAW_MINTEST -eq 0 ] && [ $RAW_MAXTEST -eq 0 ]; then
         
	# Success - Let's get the other data
	#================
	# Calc Hive Weight - Equipment Weight
	#================
	BASEWEIGHT=`echo "($HIVE_BASE_SOLID_BOTTOM_BOARD_WEIGHT * $NUM_HIVE_BASE_SOLID_BOTTOM_BOARD) + ($HIVE_BASE_SCREENED_BOTTOM_BOARD_WEIGHT * $NUM_HIVE_BASE_SCREENED_BOTTOM_BOARD) + ($HIVE_FEEDER_WEIGHT * $NUM_HIVE_FEEDER) + ($HIVE_TOP_INNER_COVER_WEIGHT * $NUM_HIVE_TOP_INNER_COVER) + ($HIVE_TOP_TELE_COVER_WEIGHT * $NUM_HIVE_TOP_TELE_COVER) + ($HIVE_TOP_MIGRATORY_COVER_WEIGHT * $NUM_HIVE_TOP_MIGRATORY_COVER)" |bc`
	BODYWEIGHT=`echo "($HIVE_BODY_MEDIUM_FOUNDATION_WEIGHT * $NUM_HIVE_BODY_MEDIUM_FOUNDATION) + ($HIVE_BODY_MEDIUM_FOUNDATION_LESS_WEIGHT * $NUM_HIVE_BODY_MEDIUM_FOUNDATION_LESS) + ($HIVE_BODY_DEEP_FOUNDATION_WEIGHT * $NUM_HIVE_BODY_DEEP_FOUNDATION) + ($HIVE_BODY_DEEP_FOUNDATION_LESS_WEIGHT * $NUM_HIVE_BODY_DEEP_FOUNDATION_LESS) + ($HIVE_BODY_SHAL_FOUNDATION_WEIGHT * $NUM_HIVE_BODY_SHAL_FOUNDATION) + ($HIVE_BODY_SHAL_FOUNDATION_LESS_WEIGHT * $NUM_HIVE_BODY_SHAL_FOUNDATION_LESS)" |bc`
	MISCWEIGHT=`echo "$HIVE_TOP_WEIGHT + $HIVE_COMPUTER_WEIGHT + $HIVE_MISC_WEIGHT" |bc`
	COMBINEDWEIGHT=`echo "$BASEWEIGHT + $BODYWEIGHT + $MISCWEIGHT" |bc`
	HIVEWEIGHT=`echo "$RAWWEIGHT - $COMBINEDWEIGHT" |bc`
	RAW2=$(echo "scale=2; ($RAWWEIGHT/1)" |bc)
	echo "We did this"
else
	#Something bad happened, set values to zero and exit
        loglocal "$DATE" WEIGHT ERROR "Raw weight was $RAWWEIGHT which exceeded 1500 or was less than 0, setting value to 0"	
         RAW2="0"
         HIVEWEIGHT="0"
fi

if [[ -z "$RAW2" ]] || [[ -z "$HIVEWEIGHT" ]];  then
	 loglocal "$DATE" WEIGHT ERROR "Unknown Error"	
	 echo "unknown error"
	echo "0 0"
else
echo "$RAW2 $HIVEWEIGHT"
fi

