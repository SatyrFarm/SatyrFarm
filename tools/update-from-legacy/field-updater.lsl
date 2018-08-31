//### updater.lsl
/**
This script is used to upgrade SatyrFarm items.
It scans for upgradeable items nearby (96m), asks for it's version and a list of items in its inventory, decides what and if to upgrade and initiates the update.

#Configuration Notecards:
sfp = SatyrFarm Password
version = Current version of the farm
upgradeables = List of objects that will be upgraded, one per line
itemignore = List of items in own inventory that will not be shared while updating
uuidignore = List of ignored UUIDs that won't get updated
additions = List of additionally items to add (per line: upgradeable:item1,item2,...)
**/

string PASSWORD;
list UPGRADEABLES = [];
list ITEMIGNORE = [];
list UUIDIGNORE = [];
list ADDITIONS = [];
list myItems;

integer scan;
list clients;
integer counter;
integer counter_none;
integer counter_scan;

loadConfig()
{
    //config notecards
    if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("version") == INVENTORY_NONE)
    {
        llSay(0, "No verion or password notecard in inventory! Can't work like that.");
    }
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    if (llGetInventoryType("upgradeables") != INVENTORY_NONE)
    {
        UPGRADEABLES = llParseString2List(osGetNotecard("upgradeables"), ["\n"], []);
    }
    if (llGetInventoryType("itemignore") != INVENTORY_NONE)
    {
        ITEMIGNORE = llParseString2List(osGetNotecard("itemignore"), ["\n"], []);
    }
    if (llGetInventoryType("uuidignore") != INVENTORY_NONE)
    {
        UUIDIGNORE = llParseString2List(osGetNotecard("uuidignore"), ["\n"], []);
    }
    if (llGetInventoryType("additions") != INVENTORY_NONE)
    {
        ADDITIONS = [];
        list addnc = llParseString2List(osGetNotecard("additions"), ["\n"], []);
        integer c = llGetListLength(addnc);
        while (c--)
        {
            ADDITIONS += llParseStringKeepNulls(llList2String(addnc, c), [":"], []);
        }
    }
    //own items
    myItems = [];
    integer len = llGetInventoryNumber(INVENTORY_ALL);
    while (len--)
    {
        myItems += [llGetInventoryName(INVENTORY_ALL, len)];
    }
}

scanNext()
{
    string target = llList2String(UPGRADEABLES, scan);
    if (target == "")
    {
        llSay(0, "Update finished.\nScanned for " + (string)counter_scan + "objects.\nUpdated " + (string)counter + " objects.\nUpdate not neccessary on " + (string)counter_none + " objects.\n" );
        llResetScript();
        return;
    }
    llSay(0, "Scanning for " + target);
    llSetText("Updating " + target + "!", <1.0,0.0,0.0>, 1.0);
    ++scan;
    llSensor(target, "", SCRIPTED, 96, PI);
}

string itemsToReplace(string sItems, key kObject)
{
    list lReplace = [];
    integer found_add = llListFindList(ADDITIONS, [llKey2Name(kObject)]) + 1;
    if (found_add)
    {
        lReplace += llParseString2List(llList2String(ADDITIONS, found_add), [","], []);
    }
    list lItems = llParseString2List(sItems, [","], []);
    integer c = llGetListLength(lItems);
    while (c--)
    {
        string item = llList2String(lItems, c);
        if (llListFindList(myItems, [item]) != -1 && llListFindList(ITEMIGNORE, [item]) == -1 && llListFindList(lReplace, [item]) == -1)
        {
            lReplace += [item];
        }
    }
    return llDumpList2String(lReplace, ",");
}


default
{
    state_entry()
    {
        llSetText("Click to Update!", <1.0,0.0,0.0>, 1.0);
        loadConfig();
    }

    touch_start(integer n)
    {
        state update;
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
}


state update
{
    state_entry()
    {
        llSetText("Update Running!", <1.0,0.0,0.0>, 1.0);
        counter = 0;
        counter_none = 0;
        counter_scan = 0;
        scan = 0;
        scanNext();
    }

    sensor(integer n)
    {
        clients = [];
        key owner = llGetOwner();
        while (n--)
        {
            key det = llDetectedKey(n);
            if (owner == llGetOwnerKey(det) && llListFindList(UUIDIGNORE, [(string)det]) == -1)
            {
                clients += [det];
            }
        }
        llSetTimerEvent(1.0);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if (clients == [])
        {
            scanNext();
            return;
        }
        key target = llList2Key(clients, 0);
        clients = llDeleteSubList(clients, 0, 0);
        llSay(0, " \n-------------\nChecking " + llKey2Name(target) + "\n" + (string)target);
        llSetTimerEvent(3.0);
        ++counter_scan;
        osMessageObject(target, "VERSION-CHECK|" + PASSWORD + "|" + (string)llGetKey());
    }

    no_sensor()
    {
        llSay(0, "No item found");
        scanNext();
    }

    dataserver(key k, string m)
    {
        list cmd = llParseString2List(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);

        if (command == "VERSION-REPLY")
        {
            integer iVersion = llList2Integer(cmd,3);
            if(iVersion == 0)
            {
                string repstr = itemsToReplace(llList2String(cmd,4), llList2Key(cmd, 2));
                if (repstr != "")
                {
                    llSay(0, "Update possible. Try to update item.");
                    osMessageObject(llList2Key(cmd, 2), "DO-UPDATE|"+PASSWORD+"|"+(string)llGetKey()+"|"+repstr);
                    llSetTimerEvent(20.0);
                    return;
                }
            }
            ++counter_none;
            llSetTimerEvent(0.5);
        }
        else if (command == "DO-UPDATE-REPLY")
        {
            llSleep(2.0);
            key kobject = llList2Key(cmd, 2);
            integer ipin = llList2Integer(cmd, 3);
            list litems = llParseString2List(llList2String(cmd, 4), [","], []);
            integer d = llGetListLength(litems);
            while (d--)
            {
                string sitem = llList2String(litems, d);
                if (llListFindList(ITEMIGNORE, [sitem]) == -1)
                {
                    integer type = llGetInventoryType(sitem);
                    else if (type == INVENTORY_SCRIPT)
                    {
                        llRemoteLoadScriptPin(kobject, sitem, ipin, TRUE, 0);
                    }
                    else if (type != INVENTORY_NONE)
                    {
                        llGiveInventory(kobject, sitem);
                    }
                }
            }
            llSay(0, "Updated items: \n    " + llList2String(cmd,4) + "\n-----------");
            ++counter;
            llSetTimerEvent(1.0);
        }
    }
}
