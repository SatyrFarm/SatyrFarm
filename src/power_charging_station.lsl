/* Charging station takes power from power controller to charge the nearest SF vehicle
*/ 

string PASSWORD="*";
key vehicle;
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

integer energy_channel = -321321;


integer lastTs=0;

string lookingFor;


water(key u)
{
        llParticleSystem(
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_SRC_BURST_RADIUS,.2,
            PSYS_SRC_ANGLE_BEGIN,0.,
            PSYS_SRC_ANGLE_END,.5,
            PSYS_PART_START_COLOR,<0, 1., .9>,
            PSYS_PART_END_COLOR,<0, 1., .9>,
            PSYS_PART_START_ALPHA,.9,
            PSYS_PART_END_ALPHA,.0,
            PSYS_PART_START_GLOW,0.0,
            PSYS_PART_END_GLOW,0.0,
            PSYS_PART_START_SCALE,<.1000000,.1000000,0.00000>,
            PSYS_PART_END_SCALE,<.9000000,.9000000,0.000000>,
            PSYS_SRC_TEXTURE,llGetInventoryName(INVENTORY_TEXTURE,0),
            PSYS_SRC_TARGET_KEY, u,
            PSYS_SRC_MAX_AGE,3,
            PSYS_PART_MAX_AGE,4,
            PSYS_SRC_BURST_RATE, .01,
            PSYS_SRC_BURST_PART_COUNT,3,
            PSYS_SRC_ACCEL,<0.000000,0.000000,-1.1>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,1,
            PSYS_SRC_BURST_SPEED_MAX,2,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_EMISSIVE_MASK |
                PSYS_PART_TARGET_POS_MASK | 
                PSYS_PART_INTERP_COLOR_MASK | 
                PSYS_PART_INTERP_SCALE_MASK
        ] );
        
       llTriggerSound(llGetInventoryName(INVENTORY_SOUND,0), 1.0);
}
 


refresh()
{
 
    llParticleSystem([]);
}

default
{
    on_rez(integer n)
    {
        llResetScript();
    }
    
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id,  "INIT|"+PASSWORD+"|100|-1|<1.000, 0.965, 0.773>|");
    }
    
    
    state_entry()
    {
        //llSetLinkTextureAnim(2, PING_PONG|ROTATE| SMOOTH |LOOP, ALL_SIDES, 0, 0, 0, .05, .011);
        PASSWORD = llStringTrim(osGetNotecardLine("sfp", 0), STRING_TRIM);        
        lastTs = llGetUnixTime();

        llSetText("Wireless Charging station\nCharge your car here\n", <1,1,1>, 1.0);
        llStopSound();
        refresh();

    }


    touch_start(integer n)
    {

        {

           
           list opts = [];
           opts += "Charge";
           opts += "CLOSE";
           
           startListen();
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
           llSetTimerEvent(100);
           refresh();
        }
    }
    
    listen(integer c, string n ,key id , string m)
    {
        if (m == "Charge")
        {
            lookingFor = "";
            llSensor(lookingFor, "", SCRIPTED, 10, PI);
        }
        else
        {
           
        }
    }
    
    
    dataserver(key kk  , string m)
    {
         
            list cmd = llParseStringKeepNulls(m, ["|"], []);
            if (llList2String(cmd,0) == "HAVEENERGY" && llList2String(cmd,1) == PASSWORD )
            {
                llSleep(1);
                water(vehicle);
                llSay(0,"Charging "+llKey2Name(vehicle)+"...");
                osMessageObject(vehicle, "KWH|"+PASSWORD+"|"+(string)llGetKey());
            }
            else if (llList2String(cmd,0) == "NOENERGY" && llList2String(cmd,1) == PASSWORD )
            {
                llSay(0,"There is not enough energy to charge your car. Try again later");
            }
    }
    
    timer()
    {   
        checkListen();
        llSetTimerEvent(0);
    }
    
    sensor(integer n)
    {
        integer i;
        for (i=0; i < 5; i++)
        {
            if (llGetSubString(llDetectedName(i) , 0, 2) == "SF ")
            {
                vehicle = llDetectedKey(i);
                llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
                llSay(0, "Trying to charge your car"+llDetectedName(i)+"...");
                return;
            }
        }
        llSay(0, "Cannot detect your SF car. Come closer");
    }
    
    no_sensor()
    {
        llWhisper(0, "Error! "+lookingFor+" not found! You must bring it near me!");
    }   

}

