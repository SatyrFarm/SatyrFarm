//### storage-dropin.lsl
/**
This helper script provides the Update-API for old storages.
Insert this script in your Fridge/Storage Rack, then use the update box.
**/

string PASSWORD = "farm";
list ITEMS;
list LEVELS;

default
{
    state_entry()
    { 
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1)
        {
            string me = llGetScriptName();
            llOwnerSay("Script " + me + " went to sleep inside Updater.");
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        llSetRemoteScriptAccessPin(0);
        //check name
        string name = llGetObjectName();
        if (name != "SF Storage Rack" && name != "SF Fridge")
        {
            llOwnerSay("NOPE NOPE NOPE NOPE NOPE NOPE!!!");
            llRemoveInventory(llGetScriptName());
        }
        llSay(0,"Preparing " + name);
        ITEMS = [];
        LEVELS = [];
        //get list of items
        llSay(0, "Getting Levels");
        integer len = llGetInventoryNumber(INVENTORY_OBJECT);
        while (len--)
        {
            string item = llGetSubString(llGetInventoryName(INVENTORY_OBJECT, len),3,-1);
            ITEMS += [item];
            LEVELS += [0];
        }
        //get their levels from hovertext
        integer links = llGetNumberOfPrims();
        integer lnk;
        for (lnk = 1; lnk <= links; lnk++)
        {
            string desc = llList2String(llGetLinkPrimitiveParams(lnk, [PRIM_TEXT]),0);
            list lines = llParseString2List(desc, ["\n"], []);
            integer linecnt = llGetListLength(lines);
            while (linecnt--)
            {
                list words = llParseString2List(llList2String(lines,linecnt), [":", " ", "%", "\n"], []);
                string curitem = llDumpList2String(llList2List(words, 0, -2), " ");
                integer found = llListFindList(ITEMS, [curitem]);
                if (found != -1)
                {
                    LEVELS = llListReplaceList(LEVELS, [llList2Integer(words, -1)], found, found);
                }
            }
        }
        llSay(0, "items: \n" + llDumpList2String(ITEMS, ",") + "\nlevels: \n" + llDumpList2String(LEVELS, ","));
        //Remove everything except myself
        len = llGetInventoryNumber(INVENTORY_ALL);
        while (len--)
        {
            string item = llGetInventoryName(INVENTORY_ALL, len);
            if (item != llGetScriptName())
                llRemoveInventory(item);
        }
        //write status notecard
        osMakeNotecard("storagenc", (string)llGetKey() + ";" + llDumpList2String(ITEMS, ",") + ";" + llDumpList2String(LEVELS, ","));
        //write notecard
        osMakeNotecard("sfp", PASSWORD);
        //done preparing
        state ready;
    }
}


state ready
{
    state_entry()
    {
        llSetText("Ready For Update!", <1,0,0>, 1.0);
        llSay(0, "Ready for update.");
    }

    dataserver(key k, string m)
    {
        list cmd = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);
        //for updates
        if (command == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|" + (string)llGetKey() + "|0||";
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
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item != me && llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            llSay(0, "Removing myself for update.");
            llRemoveInventory(me);
        }
        //
    }
}
