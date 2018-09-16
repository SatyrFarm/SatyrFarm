//### storage.lsl
/** 
Storage rack - stores multiple products. The script scans its inventory to generate the list of products automatically. 
It uses the linked prims with the same name to set text   with the status of each product. E.g. for SF Olives the linked prim named 
"Olives" is used to show the text about  the  current level  of SF Olives.

Format of config notecard:
#
# How far to search for product to add
SENSOR_DISTANCE=10
#

**/
integer VERSION=1;

string PASSWORD="*";
integer doReset;
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}
//for notecard config saving
key ownkey;
integer saveNC;
//status variables
list products = [];
list levels = [];
list customOptions = [];
list customText = [];
//listens and menus
integer listener=-1;
integer listenTs;
integer startOffset=0;
integer lastTs;
//config options for storage
//(adjustable in config notecard)
vector rezzPosition = <0,1.5,2>;
integer initialLevel = 5;
integer dropTime = 86400;
integer singleLevel = 10;
integer SENSOR_DISTANCE=10;
//temp 
string lookingFor;
string status;
list selitems = [];


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
        selitems = [];
    }
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, ["CLOSE"]+buttons, ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(buttons, startOffset, startOffset + 9);
    llDialog(id, message, ["CLOSE"]+its+[">>"], ch);
}

loadConfig(integer checkForReset)
{ 
    integer i;
    //sfp Notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    doReset = (integer)osGetNotecardLine("sfp", 1);
    //config Notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string tkey = llList2String(tok, 0);
                string tval = llList2String(tok, 1);
                if (tkey == "REZ_POSITION") rezzPosition = (vector)tval;
                else if (tkey == "INITIAL_LEVEL") initialLevel = (integer)tval;
                else if (tkey == "DROP_TIME") dropTime = (integer)tval * 86400;
                else if (tkey == "ONE_PART") singleLevel = (integer)tval;
                else if (tkey == "SENSOR_DISTANCE") SENSOR_DISTANCE = (integer)tval;   // How far to look for items
            }
        }
    }
    //storagenc Notecard
    list storageNC = llParseString2List(llStringTrim(osGetNotecard("storagenc"), STRING_TRIM), [";"], []);
    if ((llGetListLength(storageNC) < 3 || (llList2Key(storageNC, 0) != ownkey && llList2String(storageNC, 0) != "null")) && doReset && checkForReset)
    {
        if (doReset == 1)
        {
            llSay(0, "Reset");
            saveNC = 2;
            if (llGetInventoryType("storagenc-old") == INVENTORY_NOTECARD)
            {
                saveNC++;
                llRemoveInventory("storagenc-old");
            }
            osMakeNotecard("storagenc-old", "null;" + llDumpList2String(llList2List(storageNC, 1, -1), ";"));
            llRemoveInventory("storagenc");
            products = [];
            levels = [];
        }
        else
        {
            doReset = -1;
        }
    }
    else
    {
        products = llParseString2List(llList2String(storageNC,1), [","], []);
        levels = llParseString2List(llList2String(storageNC,2), [","], []);
    }
    //objects in inventory
    for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
    {
        string name = llGetInventoryName(INVENTORY_OBJECT, i);
        if (llGetSubString(name,0,2) == "SF ")
        {
            string product = llGetSubString(name,3,-1);
            if (llListFindList(products, [product]) == -1)
            {
                products += product;
                levels += initialLevel;
            }
        }
    }
    llOwnerSay(llList2CSV(products));
}

saveConfig()
{
    saveNC++;
    //storage Notecard
    if (llGetInventoryType("storagenc") == INVENTORY_NOTECARD)
    {
        saveNC++;
        llRemoveInventory("storagenc");
    }
    osMakeNotecard("storagenc", (string)ownkey + ";" + llDumpList2String(products, ",") + ";" + llDumpList2String(levels, ","));
}

refresh()
{
    integer ts = llGetUnixTime();   
    float l;
    integer i;
    if (ts - lastTs > dropTime)
    {
            for (i=0; i < llGetListLength(products); i++)
            {
                l = llList2Float(levels,  i);
                l-= 1.0;
                if (l <0) l=0;
                levels = llListReplaceList(levels, [l], i,i);
            }
            lastTs = ts;
    }
    
    integer found = 0;
    string statTotal = "";
    for (i=0; i < llGetListLength(products); i++)
    {
        float lev = llList2Float(levels, i);
        string product = llList2String(products, i);
        string stati = llList2String(products,i)+": "+(string)llRound(lev)+"%\n";
        statTotal += "\n" + stati;
        integer lnk;
        for (lnk=2; lnk <= llGetNumberOfPrims(); lnk++)
        {
            //methode one: show status of specific products on linked prims
            if (llGetLinkName(lnk) == product)
            {
                found++;
                vector c = <.6,1,.6>;
                if (lev < 10)
                    c = <1,0,0>;
                else  if (lev<50)
                    c = <1,1,0>;
                list pstate = llGetLinkPrimitiveParams(lnk, [PRIM_POS_LOCAL, PRIM_DESC]);
                vector p = llList2Vector(pstate, 0);
                list desc = llParseStringKeepNulls(llList2String(pstate, 1), [","], []);
                if (llGetListLength(desc) == 2)
                {
                    float minHeight = llList2Float(desc, 0);
                    float maxHeight = llList2Float(desc, 1);
                    p.z = minHeight + (maxHeight-minHeight)*0.99*lev/100;
                    llSetLinkPrimitiveParamsFast(lnk, [PRIM_POS_LOCAL, p]);
                }
                llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXT, stati, c, 1.0]);
            }
        }
    }
    string customStr = "";
    i = llGetListLength(customText);
    while (i--)
    {
        customStr = llList2String(customText, i) + "\n";
    }
    if (found == 0)
    {
        //if no link gets status text, display everything on the root prim
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXT, customStr + statTotal, <1,1,1>, 1.0]);
    }
    else
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXT, customStr, <1,1,1>, 1.0]);
    }
    llMessageLinked(LINK_SET, 99, "STORESTATUS|"+(string)singleLevel+"|"+llDumpList2String(products, ",")+"|"+llDumpList2String(levels, ","), NULL_KEY);
}

rezzItem(string m)
{
    integer idx = llListFindList(products, [m]);
    if (idx >=0 && llList2Integer(levels,idx) >=singleLevel)
    {
        integer l = llList2Integer(levels,idx);
        l-= singleLevel; 
        if (l <0) l =0;
        levels = [] + llListReplaceList(levels, [l], idx, idx);;
        llRezObject("SF "+m, llGetPos() + rezzPosition*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
        saveConfig();
        refresh();
    }
    else llSay(0, "Sorry, there is not enough "+m);
}

getItem(string m)
{
    integer idx = llListFindList(products, [m]);
    if (idx >=0 && llList2Integer(levels,idx) >=100)
    {
        llSay(0, "I am full of "+m);
    }
    else
    {
        lookingFor = "SF " +m;
        llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
    }
}


default 
{ 
    listen(integer c, string nm, key id, string m)
    {
        //pre-select product if there is just one
        string product = "";
        if (llGetListLength(products) == 1)
        {
            product = llList2String(products, 0);
        }
        //parse buttons
        if (m == "CLOSE") 
        {
            refresh();
        }
        else if (m == "Add Product")
        {
            if (product != "")
            {
                getItem(product);
                list opts = ["CLOSE", "Add Product", "Get Product"] + customOptions;
                llDialog(id, "Select", opts, chan(llGetKey()));
            }
            else
            {
                status = "Sell";
                multiPageMenu(id, "Select product to store", products);
            }
            return;
        }
        else if (m == "Get Product")
        {
            if (product != "")
            {
                rezzItem(product);
                list opts = ["CLOSE", "Add Product", "Get Product"] + customOptions;
                llDialog(id, "Select", opts, chan(llGetKey()));
            }
            else
            {
                status = "Get";
                multiPageMenu(id, "Select product to get", products);
            }
            return;
        }
        else if (m == "Check")
        {
            integer i;
            string str="Levels:\n";
            for (i=0;  i < llGetListLength(products); i++)
            {
                str += llList2String(products, i)+": "+(string)((integer)llList2Float(levels,  i))+"%\n";
            }
            llSay(0, str);
        }
        else if (status  == "Sell")
        {
            if (m == ">>")
                startOffset += 10;
            else
                getItem(m);
            multiPageMenu(id, "Select product to store", products);
            return;
        }
        else if (status  == "Get")
        {
            if (m == ">>")
                startOffset += 10;
            else
                rezzItem(m);
            multiPageMenu(id, "Select product to get", products);
            return;
        }
        else
        {
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
        }
        checkListen(TRUE);
    }
    
    dataserver(key k, string m)
    {
        list cmd = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(cmd,1) != PASSWORD ) { llSay(0, "Bad password"); return; } 
        string item = llList2String(cmd,0);
        
        if (item == "INIT")
        {
            doReset = 2;
            loadConfig(FALSE);
            saveConfig();
            llSetTimerEvent(1);
        }
        //for updates
        else if (item == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)llGetKey() + "|" + (string)VERSION + "|";
            integer len = llGetInventoryNumber(INVENTORY_OBJECT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_OBJECT, len) + ",";
            }
            len = llGetInventoryNumber(INVENTORY_SCRIPT);
            string me = llGetScriptName();
            while (len--)
            {
                string sitem = llGetInventoryName(INVENTORY_SCRIPT, len);
                if (sitem != me)
                {
                    answer += sitem + ",";
                }
            }
            answer += me;
            osMessageObject(llList2Key(cmd, 2), answer);
        }
        else if (item == "DO-UPDATE")
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
                string sitem = llList2String(lRemoveItems, d);
                if (sitem == me) delSelf = TRUE;
                else if (llGetInventoryType(sitem) != INVENTORY_NONE)
                {
                    llRemoveInventory(sitem);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        //
        else if (doReset == -1)
        {
            return;
        }
        else if (item == "GIVE")
        {
            string productName = llList2String(cmd,2);
            key u = llList2Key(cmd,3);
          //  if (!llSameGroup((u))) return;
            integer idx = llListFindList(products, [productName]);
            if (idx>=0 && llList2Float(levels, idx) > singleLevel )
            {
                integer l = llList2Integer(levels,idx);
                l-= singleLevel; 
                if (l <0) l =0;
                levels = [] + llListReplaceList(levels, [l], idx, idx);;
                osMessageObject(u, "HAVE|"+PASSWORD+"|"+productName+"|"+(string)llGetKey());
                saveConfig();
                refresh();
            }
            else llSay(0, "Not enough "+productName);
        }
        else
        {
            // Add something to the jars
            integer i;
            for (i=0; i < llGetListLength(products); i++)
            {
                if (llToUpper(llList2String(products,i)) ==  item)
                {
                    // Fill up
                    integer l = llList2Integer(levels, i);
                    l += singleLevel; if (l>100) l = 100;
                    levels = llListReplaceList(levels, [l], i,i);
                    llSay(0, "Added "+llToLower(item)+", level is now "+(string)llRound(l)+"%");
                    saveConfig();
                    refresh();
                    return;
                }
            }
        }        
    }

    on_rez(integer n)
    {
        llResetScript();
    } 

    timer()
    {
        refresh();
        checkListen(FALSE);
        llSetTimerEvent(1000);
    }

    touch_start(integer n)
    {
        if (!llSameGroup(llDetectedKey(0)) && !osIsNpc(llDetectedKey(0)))
        {
            return;
        }
        if (doReset == -1)
        {
            llSay(0, "I am locked, did you try to copy me? No cheating plz!\nYou can still unlock me, without losing any progress, just ask some trustworthy farm people :)")
            return;
        }

        status = "";
        list opts = ["CLOSE", "Add Product", "Get Product", "Check"] + customOptions;
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        llSetTimerEvent(300);
    }
    
    sensor(integer n)
    {
        //get first product that isn't already selected and has enough percentage
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (llListFindList(selitems, [obj]) == -1 && (have_percent == 100 || have_percent == 0))
            {
                ready_obj = llDetectedKey(c);
            }
        }
        //--
        if (ready_obj == NULL_KEY)
        {
            llSay(0, "Error! Full "+lookingFor+" not found nearby. You must bring it near me!");
            return;
        }
        selitems += [ready_obj];
        llSay(0, "Found "+lookingFor+", emptying...");
        osMessageObject(ready_obj, "DIE|"+(string)llGetKey());
    }
    

    no_sensor()
    {
        llSay(0, "Error! "+lookingFor+" not found nearby. You must bring it near me!");
    }
 
 
    state_entry()
    {
        //give it some time to load inventory items
        llSleep(2.0);
        //for updates
        if (osRegexIsMatch(llGetObjectName(), "(Update|Rezz)+"))
        {
            string me = llGetScriptName();
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        llSetRemoteScriptAccessPin(0);
        //
        ownkey = llGetKey();
        lastTs = llGetUnixTime();
        loadConfig();
        llMessageLinked(LINK_SET, 99, "RESET", NULL_KEY);
        llSetTimerEvent(1);
    } 

    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok, 0);
        if (cmd == "ADD_MENU_OPTION") 
        {
            customOptions += [llList2String(tok,1)];
        }
        else if (cmd == "REM_MENU_OPTION")
        {
            integer findOpt = llListFindList(customOptions, [llList2String(tok,1)]);
            if (findOpt != -1)
            {
                customOptions = llDeleteSubList(customOptions, findOpt, findOpt);
            }
        }
        else if (cmd == "ADD_TEXT")
        {
            customText += [llList2String(tok,1)];
        }
        else if (cmd == "REM_TEXT")
        {
            integer findTxt = llListFindList(customText, [llList2String(tok,1)]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
        }
        else if (cmd == "SETSTATUS")
        {
            products = llParseStringKeepNulls(llList2String(tok,1), [","], []);
            levels = llParseStringKeepNulls(llList2String(tok,2), [","], []);
            refresh();
        }
        else if (cmd == "GETPRODUCT")
        {
            rezzItem(llList2String(tok,1));
        }
        else if (cmd == "ADDPRODUCT")
        {
            getItem(llList2String(tok,1));
        }
        
    }
    
    object_rez(key id)
    {
        llSleep(.4);
        //products with new prod_gen notecard just need the passowrd, everything else is just here for backwards compatibility
        //and will be removed in the future
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
        llMessageLinked(LINK_SET, 91, "REZZED|"+(string)id, NULL_KEY);
    }
    
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (saveNC)
                --saveNC;
            else
                llResetScript();
        }
    }
}
