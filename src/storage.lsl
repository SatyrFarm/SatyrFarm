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
integer VERSION=2;

string PASSWORD="*";
//0 = never reset
//1 = reset when UUID doesn't metch
//2 = lock down when UUID doesn't match
//-1 = is locked down
integer doReset = 1;
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}
key ownkey;
//for notecard config saving
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
string tmpkey;
string lookingFor;
string status;
list selitems = [];


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(ownkey), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
        status = "";
        selitems = [];
    }
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(ownkey);
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
    if (osGetNumberOfNotecardLines("sfp") >= 2)
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
    list storageNC = [];
    if (llGetInventoryType("storagenc") == INVENTORY_NOTECARD)
    {
        storageNC = llParseString2List(llStringTrim(osGetNotecard("storagenc"), STRING_TRIM), [";"], []);
    }
    if ((llGetListLength(storageNC) < 3 || (llList2Key(storageNC, 0) != ownkey && llList2String(storageNC, 0) != "null")) && doReset && checkForReset)
    {
        if (doReset == 1)
        {
            llSay(0, "Reset");
            llMessageLinked(LINK_SET, 99, "HARDRESET", NULL_KEY);
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
        if (llGetListLength(storageNC) > 3)
        {
            lastTs = llList2Integer(storageNC, 3);
        }
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
                llMessageLinked(LINK_SET, 99, "GOTLEVEL|" + product + "|" + (string)initialLevel, NULL_KEY);
            }
        }
    }
    llOwnerSay(llList2CSV(products));
}

saveConfig()
{
    //storage Notecard
    if (llGetInventoryType("storagenc") != INVENTORY_NONE)
    {
        saveNC++;
        llRemoveInventory("storagenc");
    }
    saveNC++;
    osMakeNotecard("storagenc", (string)ownkey + ";" + llDumpList2String(products, ",") + ";" + llDumpList2String(levels, ",") + ";" + (string)lastTs);
}

refresh()
{
    integer ts = llGetUnixTime(); 
    integer productsLength = llGetListLength(products);
    integer lev;
    integer i;
    if (ts - lastTs > dropTime)
    {
            for (i=0; i < productsLength; i++)
            {
                lev = llList2Integer(levels,  i);
                lev-= 1;
                if (lev <0 )  lev = 0;
                levels = llListReplaceList(levels, [lev], i, i);
            }
            lastTs = ts;
    }
    
    //why should this run if nothing changed?
    integer found = 0;
    string statTotal = "";
    for (i=0; i < productsLength; i++)
    {
        lev = llList2Integer(levels, i);
        string product = llList2String(products, i);
        string stati = llList2String(products,i) + ": " + (string)lev + "%\n";
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
                else  if (lev < 50)
                    c = <1,1,0>;
                list pstate = llGetLinkPrimitiveParams(lnk, [PRIM_POS_LOCAL, PRIM_DESC]);
                vector p = llList2Vector(pstate, 0);
                list desc = llParseStringKeepNulls(llList2String(pstate, 1), [","], []);
                if (llGetListLength(desc) == 2)
                {
                    float minHeight = llList2Float(desc, 0);
                    float maxHeight = llList2Float(desc, 1);
                    p.z = minHeight + (maxHeight-minHeight) * 0.99 * (float)(lev) / 100;
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
    llMessageLinked(LINK_SET, 99, "STORESTATUS|"+(string)singleLevel+"|"+llDumpList2String(products, ",")+"|"+llDumpList2String(levels, ",")+"|"+(string)lastTs, NULL_KEY);
}

rezzItem(string m, key agent)
{
    string object = "SF " + m;
    if (llGetInventoryType(object) != INVENTORY_OBJECT)
    {
        llSay(0, object + " not in my Inventory");
        return;
    }
    integer idx = llListFindList(products, [m]);
    if (idx >= 0 && llList2Integer(levels,idx) >= singleLevel)
    {
        integer l = llList2Integer(levels,idx);
        l-= singleLevel; 
        if (l <0) l =0;
        levels = [] + llListReplaceList(levels, [l], idx, idx);;
        llRezObject(object, llGetPos() + rezzPosition*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
        llMessageLinked(LINK_SET, 99, "REZZEDPRODUCT|" + (string)agent + "|" + m, NULL_KEY);
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
        if (status == "Sell")
        {
            llSensor("", "", SCRIPTED, 10, PI);
        }
    }
    else
    {
        lookingFor = "SF " +m;
        llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
    }
}

list getAvailProducts()
{
    list availProducts = [];
    integer len = llGetListLength(products);
    while (len--)
    {
        if (llList2Integer(levels, len) >= singleLevel)
        {
            availProducts += [llList2String(products, len)];
        }
    }
    return availProducts;
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
            tmpkey = id;
            status = "Sell";
            if (product != "")
            {
                getItem(product);
                list opts = ["CLOSE", "Add Product", "Get Product"] + customOptions;
                llDialog(id, "Select", opts, chan(ownkey));
            }
            else
            {
                startOffset = 0;
                lookingFor = "all";
                llSensor("", "", SCRIPTED, 10, PI);
            }
            return;
        }
        else if (m == "Get Product")
        {
            if (product != "")
            {
                rezzItem(product, id);
                list opts = ["CLOSE", "Add Product", "Get Product"] + customOptions;
                llDialog(id, "Select", opts, chan(ownkey));
                return;
            }
            status = "Get";
            list availProducts = getAvailProducts();
            if (availProducts == [])
            {
                llSay(0, "No products available.");
            }
            else
            {
                startOffset = 0;
                multiPageMenu(id, "Select product to get", availProducts);
                return;
            }
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
            return;
        }
        else if (status  == "Get")
        {
            if (m == ">>")
                startOffset += 10;
            else
                rezzItem(m, id);
            list availProducts = getAvailProducts();
            if (availProducts != [])
            {
                multiPageMenu(id, "Select product to get", availProducts);
                return;
            }
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
            llSetRemoteScriptAccessPin(0);
            llSetTimerEvent(1);
        }
        //for updates
        else if (item == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)ownkey + "|" + (string)VERSION + "|";
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
                    ++saveNC;
                    doReset = 1;
                    llRemoveInventory(sitem);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)ownkey+"|"+(string)pin+"|"+sRemoveItems);
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
                osMessageObject(u, "HAVE|"+PASSWORD+"|"+productName+"|"+(string)ownkey);
                llMessageLinked(LINK_SET, 99, "REZZEDPRODUCT|" + (string)u + "|" + productName, NULL_KEY);
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
                    llMessageLinked(LINK_SET, 99, "GOTPRODUCT|" + (string)tmpkey + "|" + llList2String(products, i), NULL_KEY);
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
            llSay(0, "I am locked, did you try to copy me? No cheating plz!\nYou can still unlock me, without losing any progress, just ask some trustworthy farm people :)");
            return;
        }

        status = "";
        list opts = ["CLOSE", "Add Product", "Get Product", "Check"] + customOptions;
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(ownkey));
        llSetTimerEvent(300);
    }
    
    sensor(integer n)
    {
        if (lookingFor == "all")
        {
            list buttons = [];
            while (n--)
            {
                string name = llGetSubString(llKey2Name(llDetectedKey(n)), 3, -1);
                if (llListFindList(products, [name]) != -1 && llListFindList(buttons, [name]) == -1)
                {
                    buttons += [name];
                }
            }
            if (buttons == [])
            {
                if (selitems == [])
                {
                    llSay(0, "No items found nearby");
                }
                checkListen(TRUE);
            }
            else
            {
                multiPageMenu(tmpkey, "Select product to store", buttons);
            }
            return;
        }
        //get first product that isn't already selected and has enough percentage
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (llListFindList(selitems, [obj]) == -1 && (have_percent == 100 || have_percent == 0))
            {
                ready_obj = llDetectedKey(c);
                c = n;
            }
        }
        //--
        if (ready_obj == NULL_KEY)
        {
            llSay(0, "Error! Full "+lookingFor+" not found nearby. You must bring it near me!");
        }
        else
        {
            selitems += [ready_obj];
            llSay(0, "Found "+lookingFor+", emptying...");
            osMessageObject(ready_obj, "DIE|"+(string)ownkey);
        }
        if (status == "Sell")
        {
            lookingFor = "all";
            llSensor("", "", SCRIPTED, 10, PI);
        }
    }
    

    no_sensor()
    {
        if (lookingFor == "all" && selitems == [])
        {
            llSay(0, "No items found nearby");
        }
        else
        {
            llSay(0, "Error! "+lookingFor+" not found nearby. You must bring it near me!");
        }
        checkListen(TRUE);
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
        //
        ownkey = llGetKey();
        lastTs = llGetUnixTime();
        loadConfig(TRUE);
        llMessageLinked(LINK_SET, 99, "RESET", NULL_KEY);
        llSetTimerEvent(1);
    } 

    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok, 0);
        if (cmd == "ADD_MENU_OPTION") 
        {
            string option = llList2String(tok, 1);
            if (llListFindList(customOptions, [option]) == -1)
            {
                customOptions += [option];
            }
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
        else if (cmd == "RELOAD")
        {
            llResetScript();
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
            lastTs = llList2Integer(tok, 3);
            refresh();
            saveConfig();
        }
        else if (cmd == "GETPRODUCT")
        {
            rezzItem(llList2String(tok,1), id);
        }
        else if (cmd == "ADDPRODUCT")
        {
            tmpkey = id;
            checkListen(TRUE);
            getItem(llList2String(tok,1));
        }
        else if (cmd == "ADDPRODUCTNUM")
        {
            string product = llList2String(tok, 1);
            integer num = llList2Integer(tok, 2);
            integer found = llListFindList(products, [product]);
            integer level;
            if (found != -1)
            {
                level = llList2Integer(levels, found) + (num * singleLevel);
                levels = llListReplaceList(levels, [level], found, found);
                refresh();
                saveConfig();
            }
        }
        else if (cmd == "SETLEVEL")
        {
            string product = llList2String(tok, 1);
            integer level = llList2Integer(tok, 2);
            integer found = llListFindList(products, [product]);
            if (found != -1)
            {
                levels = llListReplaceList(levels, [level], found, found);
            }
            else
            {
                products += [product];
                levels += [level];
            }
            refresh();
            saveConfig();
        }
        else if (cmd == "IGNORE_CHANGED")
        {
            //next changed item event will be ignored
            ++saveNC;
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
            {
                --saveNC;
            }
            else
            {
                llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
                llResetScript();
            }
        }
    }
}
