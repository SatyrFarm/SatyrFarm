//### storage_rack.lsl
/** 
Storage rack - stores multiple products. The script scans its inventory to generate the list of products automatically. 
It uses the linked prims with the same name to set text   with the status of each product. E.g. for SF Olives the linked prim named 
"Olives" is used to show the text about  the  current level  of SF Olives.

**/
integer FARM_CHANNEL = -911201;
string PASSWORD="*";
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

list products = [];
list levels = [];
list customOptions = [];

integer listener=-1;
integer listenTs;
integer startOffset=0;
integer lastTs;

//config options for rezzing
string productAge = "10";
string drinkable = "-1";
string flowcolor = "<1.000, 0.965, 0.773>";
string productUses = "1";
string poursound = "";
vector rezzPosition = <0,1.5,2>;
//config options for storage
integer initialLevel = 5;
integer dropTime = 86400;
integer singleLevel = 10;
integer doReset = 1;

string lookingFor;
string status;


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
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
    startListen();
    llDialog(id, message, ["CLOSE"]+its+[">>"], ch);
}

loadConfig()
{ 
    integer i;
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    for (i=0; i < llGetListLength(lines); i++)
    {
        string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
        if (llGetSubString(line, 0, 0) != "#")
        {
            list tok = llParseStringKeepNulls(line, ["="], []);
            string tkey = llList2String(tok, 0);
            string tval = llList2String(tok, 1);
            if (tkey == "EXPIRETIME") productAge = tval;
            if (tkey == "READYTIME") drinkable = tval;
            if (tkey == "FLOWCOLOR") flowcolor = tval;
            if (tkey == "USES") productUses = tval;
            if (tkey == "POURSOUND") poursound = tval;
            if (tkey == "REZZ_POSITION") rezzPosition = (vector)tval;
            if (tkey == "INITIAL_LEVEL") initialLevel = (integer)tval;
            if (tkey == "DROP_TIME") dropTime = (integer)tval * 86400;
            if (tkey == "ONE_PART") singleLevel = (integer)tval;
            if (tkey == "RESET_ON_REZ") doReset = (integer)tval;
        }
    }

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


psys(key k)
{
 
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,
                        
                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    
                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 30,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
                
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
    
    for (i=0; i < llGetListLength(products); i++)
    {
        integer lnk;
        for (lnk=2; lnk <= llGetNumberOfPrims(); lnk++)
        {
            if (llGetLinkName(lnk) == llList2String(products, i))
            {
                float lev = llList2Float(levels, i);
                vector p = llList2Vector(llGetLinkPrimitiveParams(lnk, [PRIM_POS_LOCAL]), 0);
                p.z = .2 + 0.96*lev/100;
                vector c = <.6,1,.6>;
                
                if (lev < 10)
                    c = <1,0,0>;
                else  if (lev<50)
                    c = <1,1,0>;
                //TODO this thing
                //llSetLinkPrimitiveParamsFast(lnk, [PRIM_POS_LOCAL, p, PRIM_TEXT,  llList2String(products,i)+": "+llRound(lev)+"%\n" ,c, 1.0]);
                llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXT,  llList2String(products,i)+": "+(string)llRound(lev)+"%\n" ,c, 1.0]);
            }
        }
    }
    llMessageLinked(LINK_SET, 99, "STATUS|"+(string)singleLevel+"|"+llDumpList2String(products, ",")+"|"+llDumpList2String(levels, ","), NULL_KEY);
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
        refresh();
    }
    else llSay(0, "Sorry, there is not enough "+m);
}



default 
{ 

   
    
    listen(integer c, string nm, key id, string m)
    {
        if (m == "CLOSE") 
        {
            refresh();
        }
        else if (m == "Add Product")
        {
            status = "Sell";
            multiPageMenu(id, "Select product to store", products);
            return;
        }
        else if (m == "Get Product")
        {
            status = "Get";
            multiPageMenu(id, "Select product to get", products);
            return;
        }
        else if (status  == "Sell")
        {
            if (m == ">>")
            {
                startOffset += 10;
                multiPageMenu(id, "Select product to store", products);
                return;
            }
            integer idx = llListFindList(products, [m]);
            if (idx >=0 && llList2Integer(levels,idx) >=100)
            {
                llSay(0, "I am full of "+m);
            }
            else
            {
                status = "WaitProduct";
                lookingFor = "SF " +m;
                llSensor(lookingFor, "",SCRIPTED,  10, PI);
            }
        }
        else if (status  == "Get")
        {
            if (m == ">>")
            {
                startOffset += 10;
                multiPageMenu(id, "Select product to get", products);
                return;
            }
            rezzItem(m);
        }
        else
        {
            llMessageLinked(LINK_SET, 99, "MENU_OPTION|"+m, NULL_KEY);
        }
        llListenRemove(listener);
        listener = -1;
    }
    
    dataserver(key k, string m)
    {
            list cmd = llParseStringKeepNulls(m, ["|"] , []);
            if (llList2String(cmd,1) != PASSWORD ) { llSay(0, "Bad password"); return; } 
            string item = llList2String(cmd,0);
            
            if (item == "GIVE")
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
                        refresh();
                        return;
                    }
                }
            }        
    }

    on_rez(integer n)
    {
        if (doReset)
        {
            llResetScript();
        }
    } 

    timer()
    {
        refresh();
        checkListen();
        llSetTimerEvent(1000);
    }

    touch_start(integer n)
    {
        status = "";
        list opts = [];
        opts += "Add Product";
        opts += "Get Product";
        opts += customOptions;
        opts += "CLOSE";
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        llSetTimerEvent(300);
    }
    
    sensor(integer n)
    {
        if ( status == "WaitProduct")
        {
            key id = llDetectedKey(0);
            llSay(0, "Found "+lookingFor+", emptying...");
            osMessageObject(id, "DIE|"+(string)llGetKey());
            status = "";
        }
    }
    

    no_sensor()
    {

        llSay(0, "Error! "+lookingFor+" not found nearby. You must bring it near me!");
        status = "";
    }
 
 
    state_entry()
    {
        lastTs = llGetUnixTime();
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        loadConfig();
        llMessageLinked(LINK_SET, 99, "RESET", NULL_KEY);
        llSetTimerEvent(1);
    } 

    link_message(integer sender, integer val, string m, key id)
    {
        if (val == 99) return;

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
    }
    
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id, "INIT|"+PASSWORD+"|"+productAge+"|"+drinkable+"|"+flowcolor+"|"+poursound+"|"+productUses+"|");
    }
    
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            refresh();
            customOptions = [];
            llMessageLinked(LINK_SET, 99, "RESET", NULL_KEY);
        }
    }
}
