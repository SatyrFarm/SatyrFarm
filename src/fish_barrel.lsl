/** Fish barrel
**/

integer FARM_CHANNEL = -911201;
string PASSWORD="*";
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

list products = [];
list levels = [];

integer listener=-1;
integer listenTs;
integer startOffset=0;
key dlgUser;

integer lastTs;
string lookingFor;
string status;


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}




dlgSell(key id)
{
    list its = llList2List(products, startOffset, startOffset+9);
    startListen();
    llDialog(id, "Select product", ["CLOSE"]+its+ [">>"], chan(llGetKey()));

}




dlgGet(key id)
{
    list its = llList2List(products, startOffset, startOffset+9);
    startListen();
    llDialog(id, "Get menu", ["CLOSE"]+its+ [">>"], chan(llGetKey()));
    status = "Get";
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
    if (ts- lastTs > 86400)
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
                p.z = -.5 + 0.96*lev/100;
                vector c = <.6,1,.6>;
                
                if (lev < 10)
                    c = <1,0,0>;
                else  if (lev<50)
                    c = <1,1,0>;
                    
                llSetLinkPrimitiveParamsFast(lnk, [PRIM_POS_LOCAL, p, PRIM_TEXT,  llList2String(products,i)+": "+llRound(lev)+"%\nClick to get Fishing Rod" ,c, 1.0]);
                //llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXT,  llList2String(products,i)+": "+llRound(lev)+"%\n" ,c, 1.0]);
            }
        }
    }
    

}



default 
{ 

   
    
    listen(integer c, string nm, key id, string m)
    {
        if (m == "CLOSE") 
        {
            refresh();
            return;
        }
        else if (m == ">>")
        {
            startOffset += 10;
            if (startOffset >llGetListLength(products)) startOffset=0;
            dlgSell(id);
        }
        else if (m == "Get Fishing Rod")
        {
            llGiveInventory(id, "SF Fishing Rod (wear)");
            return;
        }
        else if (m == "Add Product")
        {
            dlgUser = id;
            status = "Sell";
            dlgSell(id);
        }
        else if (m == "Get Product")
        {
            dlgUser = id;
            status = "Get";
            dlgSell(id);
        }
        else if (status  == "Sell")
        {
            
            integer idx = llListFindList(products, [m]);
            if (idx >=0 && llList2Integer(levels,idx) >=100)
            {
                llSay(0, "I am full of "+m);
                status = "";
                return;
            }

            dlgUser = id;
            status = "WaitProduct";
            lookingFor = "SF " +m;
            llSensor(lookingFor, "",SCRIPTED,  10, PI);
        }
        else if (status  == "Get")
        {
            integer idx = llListFindList(products, [m]);
            if (idx >=0 && llList2Integer(levels,idx) >=10)
            {
                integer l = llList2Integer(levels,idx);
                l-= 10; 
                if (l <0) l =0;
                levels = [] + llListReplaceList(levels, [l], idx, idx);;
                llRezObject("SF "+m, llGetPos() + <0,1.5,2>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
                refresh();
            }
            else llSay(0, "Sorry, there is not enough "+m);
        }
        else
        {

        }
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
                if (idx>=0 && llList2Float(levels, idx) > 10. )
                {
                    integer l = llList2Integer(levels,idx);
                    l-= 10; 
                    if (l <0) l =0;
                    levels = [] + llListReplaceList(levels, [l], idx, idx);;
                    osMessageObject(u, "HAVE|"+PASSWORD+"|"+productName+"|"+llGetKey());
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
                        l += 10; if (l>100) l = 100;
                        levels = llListReplaceList(levels, [l], i,i);
                        llSay(0, "Added "+llToLower(item)+", level is now "+llRound(l)+"%");
                        refresh();
                        return;
                    }
                }
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

        list opts = [];
        opts += "Add Product";
        opts += "Get Product";        
        opts += "Get Fishing Rod";
        
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
            osMessageObject(id, "DIE|"+llGetKey());
        }
    }
    
    no_sensor()
    {

        llSay(0, "Error! "+lookingFor+" not found nearby. You must bring it near me!");
    }
 
 
    state_entry()
    {
        lastTs = llGetUnixTime();
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        
        

        products += "Fish";
        levels += 10;
        llOwnerSay(llList2CSV(products));
        
        llSetTimerEvent(1);
    }   
    
    
    on_rez(integer n)
    {
        llResetScript();
    }
    
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id, "INIT|"+PASSWORD+"|10|-1|<0.944,0.873,.3000>|");
    }
    
    
}
