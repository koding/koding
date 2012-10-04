#!/usr/bin/env bash

NODE_BIN="/usr/bin/env node"
FAIL=0
SUCCESS=0
TOTAL=0

cd tests

for TEST in $(ls ./*.js)
do
	if [ -f $TEST ]
	then
		TOTAL=$(($TOTAL + 1))
	fi
done

CURRENT=1
for TEST in $(ls ./*.js)
do
	if [ -f $TEST ]
	then
		TEST_FILE=$(basename $TEST)
		PERCENT=$(echo "$CURRENT / $TOTAL * 100" | bc -l | awk '{printf("%d\n",$1 + 0.5)}')
		OUTPUT="\r[$PERCENT% | $CURRENT/$TOTAL | + $SUCCESS | - $FAIL] $TEST_FILE"
		echo -ne $OUTPUT
		$NODE_BIN $TEST > /dev/null
		EXIT_CODE=$?
		if [ $EXIT_CODE -ne 0 ]
		then
			echo -e "\nFailed: $TEST_FILE"
			FAIL=$(($FAIL + 1))
		else
			SUCCESS=$(($SUCCESS+1))
		fi
		SPACER=""
		for IDX in $(seq 0 ${#OUTPUT})
		do
			SPACER=" $SPACER"
		done
		echo -ne "\r$SPACER"
		CURRENT=$(($CURRENT + 1))
	fi
done

echo ""
echo "Failed tests: $FAIL"
echo "Total tests: $TOTAL"
echo ""

if [ $FAIL -eq 0 ]
then
	exit 0
else
	exit 1
fi
