/** storage_single.lsl 


Stores a single  product. It scans the inventory to find the  product it is supposed to store, eg. if it finds SF Olives, it will store Olives. 
Sets the height and text of the linked prim named "Olives" according to the 'config' notecard.

Format of config notecard:
#
# How far to search for product to add
SENSOR_DISTANCE=10
#
# What is the Z position (relative to root) of the "Olives" linked prim when it is empty
MIN_HEIGHT=-2.0
#
# What is the Z position of the "Olives" link when it is 100% full
MAX_HEIGHT=2.0


**/

integer FARM_CHANNEL = -911201;
string PASSWORD="*";
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

string PRODUCT;
float level;

integer listener=-1;
integer listenTs;
integer startOffset=0;
key dlgUser;

integer lastTs;
string lookingFor;
string status;

integer SENSOR_DISTANCE=10;
float minHeight=-1;
float maxHeight = 1;

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
                    PSYS_SRC_BURST_PART_COUNT, 10,
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
    integer i;
    if (ts- lastTs > 86400)
    {

            level -= 1;
            if (level <0) level=0;
            
            lastTs = ts;
    }
    

        integer lnk;
        for (lnk=2; lnk <= llGetNumberOfPrims(); lnk++)
        {
            if (llGetLinkName(lnk) == PRODUCT)
            {
                float lev = level;
                vector p = llList2Vector(llGetLinkPrimitiveParams(lnk, [PRIM_POS_LOCAL]), 0);
                p.z = minHeight + (maxHeight-minHeight)*0.99*lev/100;
                
                vector c = <.6,1,.6>;
                
                if (lev < 10)
                    c = <1,0,0>;
                else  if (lev<50)
                    c = <1,1,0>;
                    
                llSetLinkPrimitiveParamsFast(lnk, [PRIM_POS_LOCAL, p, PRIM_TEXT,  PRODUCT+": "+llRound(lev)+"%\n" ,c, 1.0]);

            }
        }

    

}

loadConfig()
{
    if (llGetInventoryType("config") != INVENTORY_NOTECARD) return;
 
  
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
  if (llGetSubString(llList2String(lines,i), 0, 0) != "#")
  {
        list tok = llParseString2List(llList2String(lines,i), ["="], []);
        if (llList2String(tok,1) != "")
        {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                
                if (cmd == "SENSOR_DISTANCE")     SENSOR_DISTANCE = (integer)val;   // How far to look for items
                else if (cmd == "MIN_HEIGHT")     minHeight = (float)val;          
                else if (cmd == "MAX_HEIGHT")     maxHeight = (float)val;           
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
        else if (m == "Add "+PRODUCT)
        {
            
            if (level >=100)
            {
                llSay(0, "I am full of "+m);
                status = "";
                return;
            }

            dlgUser = id;
            status = "WaitProduct";
            lookingFor = "SF " + PRODUCT;
            llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
        }
        else if (m == "Get "+PRODUCT)
        {

            if (level>=10)
            {

                level -= 10; 
                if (level < 0) level =0;
                llRezObject("SF "+PRODUCT, llGetPos() + <0,1.5,2>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
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
                if (level > 10. )
                {
                    
                    level-= 10; 
                    if (level <0) level =0;

                    osMessageObject(u, "HAVE|"+PASSWORD+"|"+productName+"|"+llGetKey());
                    refresh();
                }
                else llSay(0, "Not enough "+productName);
            }
            else
            {
                // Add something to the jars

                    if (llToUpper(PRODUCT) ==  item)
                    {
                        // Fill up
                        
                        level += 10; if (level>100) level = 100;
                        llSay(0, "Added "+llToLower(item)+", level is now "+llRound(level)+"%");
                        refresh();
                        return;
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
        opts += "Add " + PRODUCT;
        opts += "Get " + PRODUCT;
        
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
        loadConfig();
        
        integer i;
        for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
        {
            if (llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i),0 ,2) == "SF ")
            {
                PRODUCT = llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i),3,-1);
                level = 10;
            }
        }
        llOwnerSay(PRODUCT);
        
        
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
