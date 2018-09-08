//### legacy-updater.lsl
/**
This script is used to upgrade Legacy SatyrFarm items.
It scans for upgradeable items nearby (96m), asks for a list of items in its inventory, decides what and if to upgrade and initiates the update.

#Configuration Notecards:
sfp = SatyrFarm Password
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

integer listener;
integer scan;
list clients;
integer counter;
integer counter_none;
integer counter_scan;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

loadConfig()
{
    //config notecards
    if (llGetInventoryType("sfp") == INVENTORY_NONE)
    {
        llSay(0, "No password notecard in inventory! Can't work like that.");
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
        llSay(0, "Update finished.\nScanned for " + (string)counter_scan + " objects.\nUpdated " + (string)counter + " objects.\nUpdate not neccessary on " + (string)counter_none + " objects.\n" );
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
        llSleep(2.0);
        //for updates
        if (llSubStringIndex(llGetObjectName(), "Rezz") != -1)
        {
            string me = llGetScriptName();
            llOwnerSay("Script " + me + " went to sleep inside Updater.");
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        llSetRemoteScriptAccessPin(0);
        //
        llSetText("==Legacy Updater==\nClick to Update!", <1.0,0.0,0.0>, 1.0);
        loadConfig();
    }

    state_exit()
    {
        llSetTimerEvent(0.0);
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) != llGetOwner())
        {
            llSay(0, "You are not my owner, please go away '.'");
            return;
        }
        string text = "This Updater is for LEGACY items. For old items with scripts older than 09.2018 that can't be updated on any other way.\n"
                    + "You first have to put the drop-in scripts into your items, click \"Help\" to get introductions on how to do that.\n"
                    + "\"Plant DropIn\" is for all plants and trees. \"Storage DropIn\" is for Storage Rack and Fridge.";
        llSetTimerEvent(60.0);
        llDialog(llDetectedKey(0), text, ["CLOSE", "Plant DropIn", "Storage DropIn", "UPDATE", "Help"], chan(llGetKey()));
        listener = llListen(chan(llGetKey()), "", "", "");
    }

    dataserver(key k, string m)
    {
        //for updates
        list cmd = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);
        if (command == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)llGetKey() + "|" + (string)VERSION + "|";
            integer len = llGetInventoryNumber(INVENTORY_OBJECT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_OBJECT, len) + ",";
            }
            len = llGetInventoryNumber(INVENTORY_SCRIPT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_SCRIPT, len) + ",";
            }
            answer += "|";
            len = llGetInventoryNumber(INVENTORY_NOTECARD);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_NOTECARD, len) + ",";
            }
            osMessageObject(llList2Key(cmd, 2), answer);
        }
        else if (command == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, "Reject Update, because you are not my Owner.");
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(cmd, 3);
            list lRemoveItems = llParseString2List(sRemoveItems, [","], []);
            integer delSelf = FALSE;
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item == me) delSelf = TRUE;
                else if (llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llSay(0, "Removing myself for update.");
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        //
    }

    listen(integer c, string n ,key id , string m)
    {
        if (m == "UPDATE")
        {
            state update;
        }
        else if (m == "Help")
        {
            llGiveInventory(id, "help");
        }
        else if (m == "Plant DropIn")
        {
            llGiveInventory(id, "plant-dropin");
        }
        else if (m == "Storage DropIn")
        {
            llGiveInventory(id, "storage-dropin");
        }
        llListenRemove(listener);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        llListenRemove(listener);
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
            integer c;
            for (c = 0; c < d; c++)
            {
                string sitem = llList2String(litems, c);
                if (llListFindList(ITEMIGNORE, [sitem]) == -1)
                {
                    integer type = llGetInventoryType(sitem);
                    if (type == INVENTORY_SCRIPT)
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
