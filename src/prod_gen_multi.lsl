/** #prod_gen_multi.lsl

This goes inside all the 'product' items, i.e. products rezzed by wells, plants and by processing machines. 
Configuration  of the product goes in the 'config' notecard. 
Example of 'config' notecard:
# start config
#How many days until the product expires (dies)
EXPIRES=15
#
#A product may be used more than 1 times before it is empty. How many times?
PARTS=5
#
#(Optional) When emptying the product, what color are the  particles rezzed?
FLOWCOLOR=<1.000, 0.805, 0.609>
#
#(Optional)Some products require some days to mature before they  are ready to  be used (e.g. wine) . How many days to spend in maturation?
MATURATION=10
#
#(Optional)Extra parameter that will be passed to the consumer of this
EXTRAPARAM=Nutrition:1,10,1,2

# end config


(optional) Drop a sound inside the product object that will be played when using the object
(optional) Drop a texture inside the product for the particles rezzed when used

**/ 

key followUser=NULL_KEY;
float uHeight=0;
integer lastTs;
string PASSWORD="";
integer EXPIRES = -1;
integer DRINKABLE = -1;
integer PARTS = 1;
vector FLOWCOLOR=<1.000, 0.805, 0.609>;
string extraParam; // Params to be passed from config notecard to the target object



string myName()
{
    return llGetSubString(llGetObjectName(), 3, -1);
}

refresh()
{
    integer days = llFloor((llGetUnixTime()- lastTs)/86400);
    string str = myName() + "\n";
    
    if (EXPIRES>0)
    {
        str += "Expires in "+(string)(EXPIRES-days)+ " days\n";
        if (days > EXPIRES)
        {
            llSay(0, "I have expired! Removing...");
            llDie();
        }
    }
    
    if ((DRINKABLE-days)>0) 
    {
        str += "Not ready yet ... " +(string)(DRINKABLE-days)+" days left\n";
    }

    if (PARTS>1)
    {
       str += (string)PARTS + " Uses left\n";
    }
        
    llSetText( str, <1,1,1>, 1.0);
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


loadConfig()
{   
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
                    if (cmd =="EXPIRES") EXPIRES = (integer)val;
                    else if (cmd == "PARTS")     PARTS = (integer)val;
                    else if (cmd == "FLOWCOLOR")     FLOWCOLOR = (vector) val;
                    else if (cmd == "MATURATION")     DRINKABLE = (integer)val;
                    else if (cmd == "EXTRAPARAM")     extraParam = val;
            }

        }
    }
}

default
{

    on_rez(integer n)
    {
        llResetScript();
    }
    
    state_entry()
    {
        loadConfig();
        llSetText("", <1,1,1>, 1.0);
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
                    //rotation r2 = llRotBetween(<1,0,0>,vn);

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

    dataserver(key id, string msg)
    {
        list tk = llParseStringKeepNulls(msg, ["|"], []);

        string cmd = llList2String(tk, 0);
        if (cmd == "DIE")
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
            osMessageObject(u, llToUpper(myName())+"|"+PASSWORD +"|"+(string)PARTS+"|"+extraParam);
            --PARTS;
            if (PARTS <= 0)
            {
                llDie();
            }
            llSetRot(llEuler2Rot(<0,0,0>));
            refresh();
        }
        else if (cmd == "INIT")
        {        
            PASSWORD = llList2String(tk,1);
            reset();
        }
        else if (cmd == "SET")
        {
            if(llList2String(tk, 1) != PASSWORD)
            {
                return;
            }
            integer days = llFloor((llGetUnixTime()- lastTs)/86400);
            integer found_expire = llListFindList(tk, ["EXPIRE"]) + 1;
            integer found_drinkable = llListFindList(tk, ["MATURATION"]) + 1;
            integer found_parts = llListFindList(tk, ["USES"]) + 1;
            if (found_expire) EXPIRES = days + llList2Integer(tk, found_expire);
            else if (found_drinkable) DRINKABLE = days + llList2Integer(tk, found_drinkable);
            else if (found_parts) PARTS = llList2Integer(tk, found_parts);
        }
    }
}
