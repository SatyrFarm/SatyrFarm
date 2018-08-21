/**
** 
** Region-wide power grid controller. Accepts energy from wind turbines and gives to anyone who asks. Uses a regionwide channel.
**/


integer FARM_CHANNEL = -911201;
string PASSWORD="*";
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


float energy=20.;
integer lastTs;

integer channel = -321321;

string status;



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
    llSetText("Energy Controller\nNetwork capacity: "+llRound(energy)+" kWh\n" , <1,1,1>, 1.0);
    energy -= energy* (llGetUnixTime()  - lastTs)/86400.;
    if (energy<0) energy=0;
    lastTs = llGetUnixTime();
}



default 
{ 

    listen(integer c, string n, key id, string m)
    {
        
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk,0);
        if (llList2String(tk,1) != PASSWORD) return;
        
        if (cmd == "ADDENERGY") // Add energy
        {
            energy += 1;
            psys(NULL_KEY);
            refresh();
            psys(id);
        }
        else if (cmd == "GIVEENERGY")
        {
            if (energy>0)
            {
                energy -= 1;
                if (energy<0) energy =0;
                osMessageObject(id, "HAVEENERGY|"+PASSWORD);
                psys(id);
            }
            else
            {
                osMessageObject(id, "NOENERGY|"+PASSWORD);
            }
            refresh();
        }
    }

    
    timer()
    {
        refresh();
    }

    sensor(integer n)
    {
        if ( status == "WaitWater")
        {
            llSay(0, "Found water bucket, emptying...");
            osMessageObject(llDetectedKey(0), "DIE "+llGetKey());
        }
    }
    
    no_sensor()
    {
        if (status == "WaitWater")
            llSay(0, "Error! Water bucket not found nearby! You must bring a water bucket near me!");
    }
 
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        llListen(channel, "", "", "");
        lastTs =  llGetUnixTime();
        refresh();
        llSetTimerEvent(1000);

    }   
    
    on_rez(integer n)
    {
        llResetScript();
    }
    
    
    
    
    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            if (energy <=0)
            {
                llSay(0, "There is not energy, sorry");
                return;
            }

            energy -= 1;
            if (energy < 0) energy =0;
            llRezObject(llGetInventoryName(INVENTORY_OBJECT,0), llGetPos() + <0,0,2>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
            refresh();

        }
        else llSay(0, "We are not in the same group");

    }
    
      
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id, "INIT|"+PASSWORD+"|1|-1|<0.344,0.673,1.000>|");
    }
    
    
}
