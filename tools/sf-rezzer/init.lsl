//### init.lsl
/**
This script is used to send the INIT message to SatyrFarm items that got locked down (after load from OAR or whatever).

#Configuration Notecards:
unlockables = List of objects that will be upgraded, one per line
**/

string PASSWORD;
list UNLOCKABLES = [];
integer scan;
integer counter;

scanNext()
{
    string target = llList2String(UNLOCKABLES, scan);
    if (target == "")
    {
        llSay(0, "Unlocking finished.\nUnlocked " + (string)counter + " objects." );
        llResetScript();
        return;
    }
    llSay(0, "Scanning for " + target);
    llSetText("Unlocking " + target + "!", <1.0,0.0,0.0>, 1.0);
    ++scan;
    llSensor(target, "", SCRIPTED, 96, PI);
}

default
{
    state_entry()
    {
        llSetText("Click to unlock items!", <1.0,0.0,0.0>, 1.0);
        //config notecards
        if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("unlockables") == INVENTORY_NONE)
        {
            llSay(0, "No version or unlockables notecard in inventory! Can't work like that.");
        }
        PASSWORD = osGetNotecardLine("sfp", 0);
        UNLOCKABLES = llParseString2List(osGetNotecard("unlockables"), ["\n"], []);
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) != llGetOwner())
        {
            llSay(0, "You are not my owner, please go away '.'");
            return;
        }
        state unlock;
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
}


state unlock
{
    state_entry()
    {
        llSetText("Update Running!", <1.0,0.0,0.0>, 1.0);
        counter = 0;
        scan = 0;
        llSetTimerEvent(0.5);
    }

    sensor(integer n)
    {
        key owner = llGetOwner();
        while (n--)
        {
            key det = llDetectedKey(n);
            if (owner == llGetOwnerKey(det))
            {
                llSay(0, "\nSend INIT to " + llKey2Name(det) + "\n" + (string)det);
                osMessageObject(det, "INIT|" + PASSWORD);
                counter++;
            }
        }
        llSetTimerEvent(3.0);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        scanNext();
    }

    no_sensor()
    {
        llSay(0, "No item found");
        scanNext();
    }
}
