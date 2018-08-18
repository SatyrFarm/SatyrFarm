integer FARM_CHANNEL = -911201;

key followUser=NULL_KEY;
float uHeight=0;
float OFFSET=1.;
integer moving=0;
integer lastTs;
integer isEnabled =0;
string PASSWORD="";
integer EXPIRES = -1;
integer DRINKABLE = -1;
integer PARTS = 10;
vector FLOWCOLOR=<1.000, 0.805, 0.609>;
key POURSND = "e12bc097-609b-4912-8ba0-3569b9a8d5a9";


string myName()
{
    return llGetSubString(llGetObjectName(), 3, -1);
}

refresh()
{
    integer days = llFloor((llGetUnixTime()- lastTs)/86400);
    
    string str = myName() + "\nExpires in "+(string)(EXPIRES-days)+ " days\n";
    
    if (DRINKABLE>0) 
    {
        str += "Not ready yet ... " +(DRINKABLE-days)+" days left\n";
    }

    if (PARTS>1)
    {
       str += (string)PARTS + "  Uses";
    }
        
    llSetText( str, <1,1,1>, 1.0);

    if (EXPIRES>0 && days > EXPIRES)
    {
        llSay(0, "I have expired! Removing...");
        llDie();
    }

}


water(key u)
{
        llParticleSystem(
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_SRC_BURST_RADIUS,.2,
            PSYS_SRC_ANGLE_BEGIN,0.,
            PSYS_SRC_ANGLE_END,.5,
            PSYS_PART_START_COLOR,FLOWCOLOR,
            PSYS_PART_END_COLOR,FLOWCOLOR,
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

reset()
{
    lastTs = llGetUnixTime();
    llParticleSystem([]);
    llSetTimerEvent(900);
    refresh();
}

default
{

    on_rez(integer n)
    {
        llResetScript();
    }
    
    timer()
    {

        if (followUser!= NULL_KEY)
        {
            list userData=llGetObjectDetails((key)followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            if (llGetListLength(userData)==0)
            {
                followUser = NULL_KEY;
            }
            else
            {                
                llSetKeyframedMotion( [], []);
                llSleep(.2);
                list kf;
                vector mypos = llGetPos();
                vector size  = llGetAgentSize(followUser);
                uHeight = size.z;
                vector v = llList2Vector(userData, 1)+ <2.1, -1.0, 1.0> * llList2Rot(userData,2);
                
                float t = llVecDist(mypos, v)/10;
                if (t > .1)
                {
                    if (t > 5) t = 5;    
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;
                    rotation r2 = llRotBetween(<1,0,0>,vn);

                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += t;
                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                    llSetTimerEvent(t+1);
                 
                }
            }
           return;
        }
        
        refresh();
        llSetTimerEvent(900);
    }
    
    touch_start(integer n)
    {

        llParticleSystem([]);
        if (llSameGroup(llDetectedKey(0))|| osIsNpc(llDetectedKey(0)))
        {
            if (followUser == NULL_KEY)
            {            
                followUser = llDetectedKey(0);            
                ///llSay(0,"Following you. Touch again to stop.");
                llSetTimerEvent(1.);
            }
            else
            {
                llSetKeyframedMotion( [], []);
                followUser = NULL_KEY;
                llSleep(.2);
                llSetPos( llGetPos()- <0,0, uHeight-.2> );
            }
        }
    }

   // listen(integer c, string n, key id, string msg)
    dataserver(key id, string msg)
    {
       
        
        list tk = llParseStringKeepNulls(msg, ["|"], []);

        if (llList2String(tk,0)== "DIE")
        {
            refresh();
            integer days = llFloor((llGetUnixTime()- lastTs)/86400);
            if (DRINKABLE>0 && days < DRINKABLE)
            {
                llSay(0, "I am not ready yet");
                return;
            }
            
            key u = llList2Key(tk,1);
            llSetRot(llEuler2Rot(<0,PI/1.4, 0>));
            water(u);
            llSleep(2);
            osMessageObject(u, llToUpper(myName())+"|"+PASSWORD);
            --PARTS;
            if (PARTS <= 0)
            {
                llDie();
            }
            llSetRot(llEuler2Rot(<0,0,0>));
            refresh();
        }
        else if (llList2String(tk,0)== "INIT")
        {
        
            // rez | SF WATER| pos
            PASSWORD = llList2String(tk,1);
           
            if (EXPIRES   <0)
                EXPIRES =  llList2Integer(tk,2);

            if (DRINKABLE <0) 
                DRINKABLE =  llList2Integer(tk,3);

            FLOWCOLOR = llList2Vector(tk,4);        
            if (llList2String(tk,5) != "")
                POURSND = llList2Key(tk,5);
            reset();
        }
    }
}
