integer FARM_CHANNEL = -911201;
string PASSWORD="*";



integer totalSold;
string oswUser;
string oswToken;
key farmHTTP;
string BASEURL="http://opensimworld.com/farm/";
integer points;
key dlgUser;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


integer listener=-1;
integer listenTs;

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

float wine;
float water;
float beer;

list items = [];
list objectPrice= [];
list levels = [];


integer lastTs;
string status;
string lookingFor;

integer itemFound;

integer startOffset=0;
key userToPay;

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
    string str;
    if (oswUser != "")
    {
        str = "OSW User: "+oswUser+"\nTotal Points: "+points+"\nClick to sell your stuff\n";
    }
    else
        str = "Seller not activated. Click to activate";
    
    llSetText(str , <1,1,1>, 1.0);
}




dlgSell(key id)
{
    list its = llList2List(items, startOffset, startOffset+9);
    startListen();
    llDialog(id, "Sell menu", ["CLOSE"]+its+ [">>"], chan(llGetKey()));
    status = "Sell";
}

default 
{ 

    dataserver( key id, string m)
    {
            list tk = llParseStringKeepNulls(m, ["|"], []);
            string item = llList2String(tk,0);
            integer i;
            
            if (llList2String(tk,1) != PASSWORD) { 
                llSay(0,"bad password"); return;
            }
            
            for (i=0; i < llGetListLength(items); i++)
            {
                if (llToUpper(llList2String(items,i)) ==  item)
                {
                    // Fill up
                    //levels = llListReplaceList(levels, [100.], i,i);
                    //llGiveMoney(userToPay, llList2Integer(objectPrice, i));
                    llSay(0, "Sending item...");
                    psys(NULL_KEY);
                    farmHTTP = llHTTPRequest(BASEURL+"?act=sell&tk="+llEscapeURL(oswToken)
                    +"&Id="+llEscapeURL(id)
                    +"&Str="+llEscapeURL(m)
                    , [HTTP_METHOD, "GET"], "");
                    return;
                }
            }
            itemFound=0;
    }
    
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
            if (startOffset >llGetListLength(items)) startOffset=0;
            dlgSell(id);
        }
        else if (m == "Sell" )
        {   
             farmHTTP = llHTTPRequest(BASEURL+"?act=getmenu",  [HTTP_METHOD, "GET"], "");
             dlgUser = id;
        }
        else if (m == "Profile")
        {
           // llLoadURL(llDetectedKey(0), "Visit "+oswUser+"'s profile", "http://opensimworld.com/user/"+oswUser);
            llSay(0, "Click here to visit:  http://opensimworld.com/user/"+oswUser);
        }
        else if (m == "Activate")
        {
            status = "Activating";
            startListen();
            llTextBox(llGetOwner(), "Enter your OpenSimWorld HUD Key. You can find your key in your profile settings page: \nhttp://opensimworld.com/settings", chan(llGetKey()));
        }
        else if (status == "Activating")
        {
            llSay(0, "Activating...");
            farmHTTP = llHTTPRequest(BASEURL+"?activate="+llEscapeURL(m)+"&Id="+llEscapeURL(id), [HTTP_METHOD, "GET"], "");
            status = "";

        }
        else if (status == "Sell")
        {
            {
                string what = llGetSubString(m, 4,-1);
                integer idx = llListFindList(items, m);
                if (idx>=0)
                {
                    userToPay = id;
                    lookingFor = "SF "+llList2String(items,idx);
                    llSensor(lookingFor, "",SCRIPTED,  10, PI);
                }
                status = "WaitItem";
            }

        }
        else if (status == "WaitItem")
        {
        }
    }

    
    timer()
    {
        refresh();
        llSetTimerEvent(600);
        checkListen();
    }

    touch_start(integer n)
    {
        
        list opts = [];
        if (oswUser == "")
            opts += "Activate";
        else
        {
            opts += "Sell";
            opts += "Profile";
        }
        opts += "CLOSE";
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        llSetTimerEvent(300);
    }
    
    sensor(integer n)
    {
        itemFound=1;
        llSay(0, "Found "+llDetectedName(0)+", emptying...");
        osMessageObject(llDetectedKey(0), "DIE|"+llGetKey());
    }
    
    no_sensor()
    {
        llSay(0, "Error! "+lookingFor+" not found nearby! You must bring it near me!");
    }
 
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        refresh();
        llSetText("Seller is not active. Click to Activate", <1,1,1>, 1.0);
    }
    
    
    on_rez(integer n)
    {
        llResetScript();
    }
    
    
    
    http_response(key request_id, integer status, list metadata, string body)
    {
       // llOwnerSay(body);
        if (request_id == farmHTTP)
        {
            list tok = llParseStringKeepNulls(body, ["|"], []);
            string cmd = llList2String(tok, 0);
            if (cmd == "DISABLE")
            {
                llSay(0, llList2String(tok,1));
                llResetScript();
            }
            else if (cmd == "MENU")
            {
                items = [];
                items = llParseStringKeepNulls(llList2String(tok,1), [","], []);
                dlgSell(dlgUser);
            }
            else if (cmd == "ACTIVE")
            {
                oswToken = llList2String(tok, 1);
                oswUser = llList2String(tok, 2);
                points =  llList2Integer(tok, 3);
                llSay(0, llList2String(tok,4));
                refresh();
            }
            else 
            {
                llSay(0, ""+llList2String(tok,1));
            }
        }
    }
}
