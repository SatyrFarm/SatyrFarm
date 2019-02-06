// This script is used for bee hives and bee houses to produce honey, no food, water or other products needed.
//-- Linking multiple hives
// If multple bee hives get linked together, all scripts besides the one in the
// root prim delete itself, while the root prim script will handle all hives automatically.
// But this just works if the names of the hives are the same.
//--
string PASSWORD="*";
integer lastTs=0;
integer FILLTIME = 43200;

integer getLinkRoot(integer link_num)
{
    string name = llGetObjectName();
    while (llList2String(llGetLinkPrimitiveParams(link_num, [PRIM_NAME]), 0) != name && link_num)
    {
        --link_num;
    }
    return link_num;
}

refresh()
{
    integer do_fill = FALSE;
    if (llGetUnixTime() - lastTs >  FILLTIME)
    {
        do_fill = TRUE;
        lastTs = llGetUnixTime();
    }

    string name = llGetObjectName();
    integer num = llGetObjectPrimCount(llGetKey());
    if (num == 1) num = 0;
    integer fill;
    vector color;
    do
    {
        if (llList2String(llGetLinkPrimitiveParams(num, [PRIM_NAME]), 0) == name)
        {
            fill = llList2Integer(llParseString2List(llList2String(llGetLinkPrimitiveParams(num, [PRIM_DESC]), 0), [","], []), 0);
            if (do_fill && fill < 100)
            {
                fill += 10;
                llSetLinkPrimitiveParamsFast(num, [PRIM_DESC, (string)fill + "," + (string)lastTs]);
            }
            bees(num, 0 , .5, llGetKey());
            if (fill >= 100) color = <0.180, 0.800, 0.251>;
            else color = <1, 1, 1>;
            llSetLinkPrimitiveParamsFast(num, [PRIM_TEXT, "Honey level " + (string)fill+ "%\n", color, 1.0]);
        }
    } while (--num > 0);
}

bees(integer link, integer time, float rate, key k)
{
 
     llLinkParticleSystem(link,
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,PI/2,
                    PSYS_SRC_ANGLE_END,PI/2+.3,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,
                        
                    PSYS_PART_START_ALPHA,1.,
                    PSYS_PART_END_ALPHA,0.3,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    
                    PSYS_PART_START_SCALE,<0.070000,0.070000,0.000000>,
                    PSYS_PART_END_SCALE,<.0700000,.07000000,0.000000>,
                    PSYS_SRC_TEXTURE,"Bee",
                    PSYS_SRC_MAX_AGE,time,
                    PSYS_PART_MAX_AGE,8,
                    PSYS_SRC_BURST_RATE, rate,
                    PSYS_SRC_BURST_PART_COUNT, 1,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,.5000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,2.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, .1,
                    PSYS_SRC_BURST_SPEED_MAX, 2,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |PSYS_PART_WIND_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
                
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
        integer num = llGetObjectPrimCount(llGetKey());
        if (num == 1) num = 0;
        do
        {
            //give every hive a random color (used in one-prim bee hive)
            /*
            vector color = ZERO_VECTOR;
            color.x = 0.5 + llFrand(0.45);
            color.y = 0.5 + llFrand(0.45);
            color.z = 0.5 + llFrand(0.45);
            llSetLinkPrimitiveParamsFast(num, [PRIM_COLOR, ALL_SIDES, color, 1.0] );
            */
            //---
            string name = llGetObjectName();
            if (llList2String(llGetLinkPrimitiveParams(num, [PRIM_NAME]), 0) == name)
            {
                integer fill = llList2Integer(llGetLinkPrimitiveParams(num, [PRIM_DESC]), 0);
                if (fill < 0 || fill > 100)
                {
                    llSetLinkPrimitiveParamsFast(num, [PRIM_DESC, "20"]);
                }
            }
        } while (--num > 0);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        lastTs = llList2Integer(llParseString2List(llList2String(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_DESC]), 0), [","], []), 1);
        llSetTimerEvent(1);
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            integer hive_lnk = getLinkRoot(llDetectedLinkNumber(0));
            list prim_vars = llGetLinkPrimitiveParams(hive_lnk, [PRIM_DESC, PRIM_POSITION, PRIM_ROTATION]);

            if (llList2Integer(prim_vars, 0) < 100)
            {
                llSay(0, "There is not enough honey, sorry");
                return;
            }
            
            llSetLinkPrimitiveParamsFast(hive_lnk, [PRIM_DESC, "0"]);

            vector rez_pos = llList2Vector(prim_vars, 1) + <0, -1.4, -0.5> * llList2Rot(prim_vars, 2); //for one-prim bee hives
            //vector rez_pos = llList2Vector(prim_vars, 1) + <1.2, 0.0, 0.0> * llList2Rot(prim_vars, 2); //for old bee houses
            llRezObject(llGetInventoryName(INVENTORY_OBJECT,0), rez_pos, ZERO_VECTOR, ZERO_ROTATION, 1);

            refresh();
        }
        else llSay(0, "We are not in the same group");
    }
    
    collision_start(integer n)
    {
        llWhisper(0, "Watch out, bees!");
        integer link_num = llDetectedLinkNumber(0);
        bees(getLinkRoot(link_num), 30,  .02, llDetectedKey(0));
        llSetTimerEvent(30);
        llTriggerSound("bees", 1.0);
    }
   
    timer()
    {
        refresh();
        llSetTimerEvent(1000);
    }
    
    changed(integer change)
    {
        if (change && CHANGED_LINK)
        {
            if (llGetLinkNumber() > 1)
            {
                llSay(0, "You linked me to another object.\nThe script in the root prim should control me now.");
                llRemoveInventory(llGetScriptName());
            }
            else
            {
                llResetScript();
            }
        }
    }
}

