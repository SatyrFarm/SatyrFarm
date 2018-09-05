/* Part of the  SatyrFarm scripts
   This code is provided under the CC-BY-NC license
   */

string AN_NAME = "Animal";
string AN_FEEDER = "SF Animal Feeder";
string AN_BAAH = "Ah";
integer AN_HASGENES = 0;
integer AN_HASMILK = 0;
integer AN_HASWOOL = 0;
integer AN_HASMANURE = 0;
string name;

integer VERSION = 1;

list ADULT_MALE_PRIMS = [];

list ADULT_FEMALE_PRIMS = []; // link numbers -   Both sexes

list ADULT_RANDOM_PRIMS = []; //  show randomly

list CHILD_PRIMS = [];

list colorable = []; //[2,3,4,9,10,11,12,13,14,15,16,17];

integer FARM_CHANNEL = -911201;
string PASSWORD="*";

integer deathFlags=0;

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



/////////////////////////////


integer RADIUS=5;

integer LIFETIME = 86400*30; 

float WATERTIME = 5000. ;
float FEEDTIME  = 5900. ;

integer MILKTIME = 86400 ;
integer MANURETIME = 86400*2  ;
integer WOOLTIME = 86400*4  ;

integer PREGNANT_TIME = 86400*5;

integer lifeTime;

integer geneA=1;
integer geneB=1;
integer fatherGene;

float FEEDAMOUNT=1.;
float WATERAMOUNT=1.;

integer TOTAL_ADULTSOUNDS = 4;
integer TOTAL_BABYSOUNDS = 2;
integer IMMOBILE=0;

list rest;
list walkl;
list walkr;
list eat;
list down;
list link_scales;

integer tail;
vector initpos;

integer lastFed;
integer lastTs;
integer lastWater;
integer createdTs;
integer milkTs;
integer woolTs;
integer manureTs;
integer labelType = 0; // 1== short


float food=4.;
float water=4.;

string status = "OK";

string sex;
integer isBaby=1;
integer left;
key followUser=NULL_KEY;
integer pregnantTs;
integer givenBirth =0;
string fatherName;
integer days;
integer age;



loadConfig()
{
    
    list lines = llParseString2List(osGetNotecard("an_config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        list tok = llParseString2List(llList2String(lines,i), ["="], []);
        
        if (llList2String(tok,1) != "")
        {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                //llOwnerSay(cmd+"="+val);
                if (cmd =="NAME") AN_NAME = val;
                else if (cmd == "FEEDER") AN_FEEDER = val;
                else if (cmd == "CRY") AN_BAAH = val;
                else if (cmd == "HASGENES") AN_HASGENES = (integer)val;
                else if (cmd == "HASMILK") AN_HASMILK= (integer)val;
                else if (cmd == "HASWOOL") AN_HASWOOL= (integer)val;
                else if (cmd == "HASMANURE") AN_HASMANURE = (integer)val;
                else if (cmd == "ADULT_MALE_PRIMS") ADULT_MALE_PRIMS = llParseString2List(val, [","] , []);
                else if (cmd == "ADULT_FEMALE_PRIMS") ADULT_FEMALE_PRIMS = llParseString2List(val, [","] , []);                
                else if (cmd == "CHILD_PRIMS") CHILD_PRIMS = llParseString2List(val, [","] , []);                
                else if (cmd == "SKINABLE_PRIMS") colorable = llParseString2List(val, [","] , []);
                else if (cmd == "WOOLTIME") WOOLTIME= (integer)val;
                else if (cmd == "MILKTIME") MILKTIME= (integer)val;
                else if (cmd == "IMMOBILE") IMMOBILE = (integer)val;
                else if (cmd == "PREGNANT_TIME") PREGNANT_TIME= (integer)val;
                else if (cmd == "FEEDAMOUNT") FEEDAMOUNT= (float)val;
                else if (cmd == "WATERAMOUNT") WATERAMOUNT= (float)val;
                else if (cmd == "LIFEDAYS") LIFETIME = (integer)(86400*(float)val);
                else if (cmd == "TOTAL_BABYSOUNDS") TOTAL_BABYSOUNDS = (integer)val;
                else if (cmd == "TOTAL_ADULTSOUNDS") TOTAL_ADULTSOUNDS = (integer)val;
        }
    }

}

loadStateByDesc()
{
    //state by description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "A")
    {
        if ((llList2String(desc, 5) != (string)chan(llGetKey())) )
        {
            llSetObjectDesc("");
            llSleep(1.0);
            //llResetScript();
        }
        else
        {
            //PRODUCT_NAME = llList2String(desc, 1);
            if (llList2Integer(desc,1) == 1) sex = "Female";
            else sex = "Male";
            
            water = llList2Integer(desc, 2);
            food = llList2Integer(desc, 3);
            
            createdTs = llList2Integer(desc, 4);
            geneA = llList2Integer(desc, 6);
            geneB = llList2Integer(desc, 7);
            fatherGene = llList2Integer(desc, 8);
            pregnantTs = llList2Integer(desc, 9);
            name = llList2String(desc, 10);
        }
    } 
// llSetObjectDesc("A;"+scode+";"+(string)llRound(water)+";"+(string)llRound(food)+";"+(string)createdTs+";"+(string)chan(llGetKey())+";"+geneA+";"+geneB+";"+pregnantTs+";"+name+";");
}






setGenes()
{
    integer i;
    string tex;
    
    if (!AN_HASGENES) return;
    
    
    if (geneA == geneB)
    {
        tex = "goat"+(string)geneA;
    }
    else if (geneA<geneB)
        tex = "goat"+(string)geneA+(string)geneB;
        
    else if (geneB<geneA)
        tex = "goat"+(string)geneB+(string)geneA;

    for (i=0; i < llGetListLength(colorable); i++)
    {
        integer lnk = llList2Integer(colorable, i);
        llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE, 0, tex, <1,1,1>, <0,llFrand(1), 0> , 0]);
    }
}


    
say(integer whisper, string str)
{
    string s = llGetObjectName();
    llSetObjectName(name);
    if (whisper) llWhisper(0, str);
    else llSay(0, str);
    llSetObjectName(s);
    baah();
}



baah()
{
    if (isBaby)
        llTriggerSound("baby"+(1+(integer)llFrand(TOTAL_BABYSOUNDS)), 1.0);
    else
        llTriggerSound("adult"+(1+(integer)llFrand(TOTAL_ADULTSOUNDS)), 1.0);
}


death(integer keepBody)
{
    llSetTimerEvent(0);
    //Prepare for death
    deathFlags = keepBody;
    llRezObject("SF Meat", llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
    llRezObject("SF Skin", llGetPos() +<1,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
}


hearts()
{
     llParticleSystem(
                    [
                    PSYS_PART_FLAGS,                            
                    PSYS_PART_FOLLOW_VELOCITY_MASK|
                    PSYS_PART_EMISSIVE_MASK,
                    PSYS_SRC_PATTERN,       PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_PART_START_SCALE,      <.1,.1,0.1>,
                    PSYS_PART_START_ALPHA,      1.0,
                    PSYS_PART_START_COLOR,      <1.0,1.0,1.>,
                    PSYS_SRC_ACCEL,             <0,0,.1>,                    
                    PSYS_SRC_TEXTURE ,          "heart",
                    PSYS_PART_MAX_AGE,          8.0,
                    PSYS_SRC_MAX_AGE,          3.0,
                    PSYS_SRC_ANGLE_BEGIN,       0.0,
                    PSYS_SRC_ANGLE_END,         0.2,
                    PSYS_SRC_BURST_PART_COUNT,  36,
                    PSYS_SRC_BURST_RATE,        .1, 
                    PSYS_SRC_BURST_SPEED_MIN,   0.5, 
                    PSYS_SRC_BURST_SPEED_MAX,   1.5]);
}

setAlpha(list links, float vis)
{
    integer i;
    for (i=0; i < llGetListLength(links);i++)
    {
        llSetLinkPrimitiveParamsFast(llList2Integer(links,i), [PRIM_COLOR, ALL_SIDES, <1,1,1>, vis]);
    }
}

setpose(list pose)
{
    integer idx=0;
    integer i;
    float scale;
    if (isBaby) 
    {
        scale = 0.5 + 0.5*((float)(age)/(float)(0.15*lifeTime))*.9;
        if (scale>1) scale = 1.;
    }
    else if (sex=="Male") scale=1.1;
    else scale = 1.;
    
    for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
    {
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, llList2Vector(pose, (i-1)*2-2)*scale, PRIM_ROT_LOCAL, llList2Rot(pose, (i-1)*2-1), PRIM_SIZE, llList2Vector(link_scales, i-2)*scale]);
    }
}


move()
{
        integer i;
        integer rnd = (integer)llFrand(5);
        if (rnd==0)    setpose(rest); 
        else if (rnd==1)    setpose(down); 
        else if (rnd==2)    setpose(eat); 
        else if (IMMOBILE<=0)
        {        
            float rz = .3-llFrand(.6);
            for (i=0; i < 6; i++)
            {
                vector cp = llGetPos();
                vector v = cp + <.4, 0, 0>*(llGetRot()*llEuler2Rot(<0,0,rz>));
                v.z = cp.z;
                if ( llVecDist(v, initpos)< RADIUS)
                {
                    if (i%2==0)
                        setpose(walkl);
                    else
                        setpose(walkr);
                    llSetPrimitiveParams([PRIM_POSITION, v, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,rz>) ]);
                    llSleep(0.4);
                }
                else
                {
                    llSetPrimitiveParams([PRIM_POSITION, cp, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,PI/2>) ]);
                }
            }
            setpose(rest);     
        }
        if (llFrand(1.)< 0.5) baah();
}



refresh(integer ts)
{
            food -= (ts - lastTs)  *(100./FEEDTIME); // Food consumption rate
            water -= (ts - lastTs) * (100./WATERTIME); // water consumption rate
        
            if (food < 5 || water < 5)
            {  
                status ="WaitFood";
                llSensor(AN_FEEDER, "", SCRIPTED, 20, PI);
            }
            age = (ts-createdTs);
            
            float days = (age/86400.);
            string uc = "♂";
            if (sex == "Female")
                uc = "♀";

            string str =""+name+" "+uc+"\n";
                        
            if (isBaby && days  > (lifeTime*0.08/86400.))
            {
                isBaby=0;
                FEEDAMOUNT  = 2.;
                WATERAMOUNT = 2.;
                
                // Randomly show 
                if (sex == "Male")
                    setAlpha(ADULT_MALE_PRIMS, 1.);
                if (sex == "Female")
                    setAlpha(ADULT_FEMALE_PRIMS, 1.);
                setAlpha(CHILD_PRIMS, 0.);
                if (llFrand(1.)<0.5)
                {
                    setAlpha(ADULT_RANDOM_PRIMS, 1.);
                }
            }

            if (food < 0 && water <0) say(0, AN_BAAH+", I'm hungry and thirsty!");
            else if (food < 0) say( 0,AN_BAAH+", I'm hungry!");
            else if (water < 0) say( 0, AN_BAAH+", I'm thirsty!");

            str += ""+(integer)days+" days old ";
            if (isBaby) str += "(Child)\n";
            else 
            {
                str += "(Adult)\n";
                
                float p = 100.*(ts - milkTs)/MILKTIME;
                if (p > 100) p = 100;

                if (AN_HASMILK && sex == "Female" && givenBirth>0)
                    str += "Milk: "+(integer)p+"%\n";
                    

                p = 100.*(ts - woolTs)/WOOLTIME;
                if (p > 100) p = 100;
                if (AN_HASWOOL)
                    str += "Wool: "+(integer)p+"%\n";

            }
            
        
            if (age > LIFETIME || food < -20000 || water < -20000)
            {
                death(1);
                return;
            }
            else
            {
                if (pregnantTs>0)
                {
                    float perc = (float)(ts - pregnantTs)/PREGNANT_TIME;

                    if (perc >.99)
                    {

                        llRezObject("SF "+AN_NAME, llGetPos() +<0,2,0>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1 );

                        pregnantTs =0;
                        givenBirth++;
                        say(0, "I had a baby!");
                    }
                    else
                        str += "PREGNANT! ("+(integer)(perc*100)+"%)\n";
                }
                vector color = <1,1,1>;
                if (food>0)
                    str += "Food: "+(integer)food+"%\n";
                else
                {
                    str += "HUNGRY!\n";
                    color = <1,0,0>;
                }
                if (water>0)
                    str += "Water: "+(integer)water+"%\n";
                else
                {
                    str += "THIRSTY!\n";
                    color = <1,0,0>;
                }
        
                if (labelType == 1)
                    llSetText(name , color, 1.0);
                else
                    llSetText(str , color, 1.0);
            }
     integer scode=0;
     if (sex == "Female") scode=1;
     llSetObjectDesc("A;"+scode+";"+(string)llRound(water)+";"+(string)llRound(food)+";"+(string)createdTs+";"+(string)chan(llGetKey())+";"+(string)geneA+";"+(string)geneB+";"+(string)fatherGene+";"+pregnantTs+";"+name+";");
}



list getNC(string name)
{
    list lst = llParseString2List(osGetNotecard(name), ["|"], []);
    return lst; 
}




default
{
    state_entry()
    {

        if (llGetObjectName() == "SF Animal Rezzer")
        {
            llSetScriptState(llGetScriptName(), FALSE); // Dont run in the rezzer
            return;
        }
        
        
        loadConfig();
        
        rest =  getNC("rest");
        down = getNC("down");
        eat = getNC("eat");
        walkl = getNC("walkl");
        walkr = getNC("walkr");
        link_scales = getNC("scales");
        
        name = AN_NAME;
        
        llSetObjectName("SF "+AN_NAME);
         
        //Reset Everything
        llSetRot(ZERO_ROTATION);
        llSetLinkColor(LINK_ALL_OTHERS, <1, 1,1>, ALL_SIDES);

        
        if (llFrand(1.) < 0.5) sex = "Female";
        else sex = "Male";
        geneA = 1+ (integer)llFrand(3);
        geneB = 1+ (integer)llFrand(3);
        
        lastTs = createdTs = llGetUnixTime()-10;
        initpos = llGetPos();

        isBaby=1;
        setAlpha(ADULT_MALE_PRIMS, 0.);        
        setAlpha(ADULT_FEMALE_PRIMS, 0.);
        setAlpha(ADULT_RANDOM_PRIMS, 0.);
        setAlpha(CHILD_PRIMS, 1.);        
        lifeTime = (integer) ( (float)LIFETIME*( 1.+llFrand(.1)) );
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        
        loadStateByDesc();

        setGenes();

        llSetTimerEvent(5);
    }
    
    on_rez(integer n)
    {
        if (n >0)
            createdTs = llGetUnixTime()-10;
        lastTs = llGetUnixTime()-10;
    }
    
    object_rez(key id)
    {
        llSleep(.5);
        if (llKey2Name(id) == llGetObjectName()) //Child
        {
            string genes = (string)geneA+"|"+(string)fatherGene; 
            if (llFrand(1.)<0.5) genes =  (string)geneB+"|"+(string)fatherGene;
            string babyParams = genes+"|Baby "+fatherName+" y "+name;
            llGiveInventory(id, "sfp");
            llRemoteLoadScriptPin(id, "animal", 999, TRUE, 1);
            llSleep(2);
            osMessageObject(id,   "INIT|"+PASSWORD+"|"+babyParams);
            llGiveInventory(id, "SF "+AN_NAME);

        }
        else
        {

            osMessageObject(id, "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
            
            if (llKey2Name(id) == "SF Meat") deathFlags = deathFlags|2;
            if (llKey2Name(id) == "SF Skin") deathFlags = deathFlags|4;
            if ((deathFlags&2) && (deathFlags&4))
            {
                llSetTimerEvent(0);
                if (deathFlags&1) 
                {
                    llSetRot(llEuler2Rot(<PI/2,0,0>));
                    llSetLinkColor(LINK_ALL_OTHERS, <0.1, 0.1,0.1>, ALL_SIDES);
                    llSetText(name+"\nDEAD", <1,1,1>, 1.0);
                    llRemoveInventory(llGetScriptName());
                }                
                else 
                    llDie();
            }
        }
    }
    
    timer()
    {
        if (followUser!= NULL_KEY)
        {
            list userData=llGetObjectDetails((key)followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            if (llGetListLength(userData)==0)
            {
                followUser = NULL_KEY;
                llSetTimerEvent(1);
                return;            
            }
            else
            {
                
                vector size = llGetAgentSize(followUser);
                vector mypos = llGetPos();
                vector v = llList2Vector(userData, 1)+<0.3, 1.5, -size.z/2-0.1> * llList2Rot(userData,2);
                float d = llVecDist(mypos, v);
                if (d>2)
                {
                    vector vn = llVecNorm(v  - mypos );
                    vector fpos;
                    if (d>20) fpos = mypos + 2*vn;
                    else fpos = mypos + .7*vn;
                    vn.z =0;
                    rotation r2 = llRotBetween(<1,0,0>,vn);
                    
                    left = !left;
                    llSetPrimitiveParams([PRIM_ROTATION,r2, PRIM_POSITION, fpos]);
                    if (left)
                        setpose(walkl);
                    else
                        setpose(walkr);
                    if (llFrand(1.)< 0.1) baah();
                    initpos = fpos;
 
                }
            }
        }
        

            
        integer ts = llGetUnixTime();
        if (ts - lastTs>10)
        {
            refresh(ts);
            if (status == "DEAD") 
            {
                llSetTimerEvent(0);
                return;
            }
            else if (followUser == NULL_KEY)
            {
                llSetTimerEvent(25+ (integer)llFrand(10));
                move();
            }
            
            lastTs = ts ;
        }
        
       
        checkListen(); 
    } 
    
    listen(integer c, string n ,key id , string m)
    {
        
        if (m == "Mate" && sex == "Female")
        {
            status = "WaitMate";
            llSensor(llGetObjectName(), "", SCRIPTED, 5, PI);            
        }
        else if (m == "Follow Me")
        {
            followUser = id;
            if (followUser != NULL_KEY)
            {
                llSetTimerEvent(.5);
                llStopSound();
            }
        }
        else if (m =="Options")
        {
            list opts = ["CLOSE"];
            opts += "Set Name";
    
            if (IMMOBILE>0)  opts += "Walking On";
            else opts += "Walking Off";

            if (labelType==1) opts += "Long Label";
            else opts += "Short Label";
            
            opts += "Range";

            llDialog(id, "Select", opts, chan(llGetKey()) );
        }
        else if (m == "Range")
        {
            llTextBox(id, "Set Walking Range to (meters):", chan(llGetKey()));
            status = "WaitRadius";
        }
        else if (m == "Set Name")
        {
            llTextBox(id, "Set name to: ", chan(llGetKey()));
            status = "WaitName";
        }
        else if (m == "Stop")
        {
                integer i;
                followUser =NULL_KEY;
                llStopSound();
                setpose(rest);
                initpos = llGetPos();
                llSetTimerEvent(2);
                say(0, "OK I'll stick around");
        }
        else if (m == "Butcher")
        {
            say(0, "Goodbye, cruel world... ");
            death(0);
            return;
        }
        else if (m == "Walking On" || m == "Walking Off")    
        {
            IMMOBILE = (m == "Walking Off");
            llSay(0, "Allow walking="+(string)(!IMMOBILE));
        }
        else if (m == "Short Label" || m == "Long Label")
        {
            labelType = (m == "Short Label");
           // llSay(0, "Short label="+(string)labelType);
            refresh(llGetUnixTime());
        }
        else if (m == "Milk" && AN_HASMILK)
        {
            if (sex == "Female")
            {
                say(0, "From my tits and right into your bucket!");
                llRezObject("SF Milk", llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
                milkTs = llGetUnixTime();
            }
        }

        else if (m == "Get Manure")
        {
            if (llGetUnixTime() - manureTs > MANURETIME)
            {
                say(0, "Here is my bag of shit!");
                llRezObject("SF Manure", llGetPos() +<0,1,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
                manureTs = llGetUnixTime();
            }
        }
        else if (m == "Wool" &&AN_HASWOOL)
        {

                say(0, "Finally! I thought you'd never give me a haircut.");
                llRezObject("SF Wool", llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
                woolTs = llGetUnixTime();
        }
        else if (status == "WaitRadius")
        {
            RADIUS = (integer)m;
            if (RADIUS<1) RADIUS = 1;
            say(0, "Alright, I won't go further than "+(string)RADIUS+" meters");
            status = "OK";
        }
        else if (status =="WaitName")
        {
            name = m;
            say(0, "Hello! My name is "+name+"!");
            status ="OK";
            refresh(llGetUnixTime());
        }
        else
        {
        }
        
    }
    

    dataserver(key kk, string m)
    {
           list tk = llParseStringKeepNulls(m , ["|"], []);
            if (llList2String(tk,1) != PASSWORD)  { llOwnerSay("Password mismatch '"+llList2String(tk,1)+"'!='"+PASSWORD+"'"); return;  } 
            
        string cmd = llList2String(tk,0);
        //for updates
        if (cmd == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)llGetKey() + "|" + (string)VERSION + "|";
            integer len = llGetInventoryNumber(INVENTORY_OBJECT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_OBJECT, len) + ",";
            }
            len = llGetInventoryNumber(INVENTORY_SCRIPT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_SCRIPT, len) + ",";
            }
            answer += "|";
            len = llGetInventoryNumber(INVENTORY_NOTECARD);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_NOTECARD, len) + ",";
            }
            osMessageObject(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(kk) != llGetOwner())
            {
                llSay(0, "Reject Update, because you are not my Owner.");
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(tk, 3);
            list lRemoveItems = llParseString2List(sRemoveItems, [","], []);
            integer delSelf = FALSE;
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item == me) delSelf = TRUE;
                else if (llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
              }
              integer pin = llRound(llFrand(1000.0));
              llSetRemoteScriptAccessPin(pin);
              osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
              if (delSelf)
              {
                  llSay(0, "Removing myself for update.");
                  llRemoveInventory(me);
              }
              llSleep(10.0);
              llResetScript();
        }
        //
        else if (cmd == "MATEME" )
            {
                if (isBaby)
                {
                    say(0,  "I am a child, you pervert...");
                    return;
                }
                else if (sex != "Male")
                {
                    say(0, "Sorry honey, I'm not a lesbian");
                    return;
                }
                
                key partner = llList2Key(tk,2);
                
                list ud =llGetObjectDetails(partner, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
                llSetKeyframedMotion( [], []);
                llSleep(.2);
                list kf;
                vector mypos = llGetPos();
                vector v = llList2Vector(ud, 1) + <-.3,  .0, 0.3> * llList2Rot(ud,2);
                float t = llVecDist(mypos, v)/3;
                
                rotation trot  =  llList2Rot(ud,2);
                if (1)
                {
    
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;
                    rotation r2 = llRotBetween(<1,0,0>,vn);
    
                    kf += ZERO_VECTOR;
                    kf += (trot/llGetRot()) ;// llRotBetween(<1,0,0>*llGetRot(),  <1,0,0);
                    kf += .4;
    
                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += 3;
    
                    //kf += ZERO_VECTOR;
                    //kf += (trot/r2)  ;// llRotBetween(<1,0,0>*llGetRot(),  <1,0,0);
                    //kf += .4;
    
                    kf += ZERO_VECTOR;
                    kf += llEuler2Rot(<0,-.3,0>);  // llRotBetween(<1,0,0>*llGetRot(),  <1,0,0);
                    kf += .4;
    
                    integer k = 7;
                    while (k-->0)
                    {
                        kf += <0.2, 0,0>*trot;
                        kf += ZERO_ROTATION;
                        kf += .6;
        
                        kf += <-0.2, 0,0>*trot;
                        kf += ZERO_ROTATION;
                        kf += .6;
                    }
                    
                    kf += ZERO_VECTOR;
                    kf += llEuler2Rot(<0, .3, 0>);  // llRotBetween(<1,0,0>*llGetRot(),  <1,0,0);
                    kf += .3;
    
                    kf += <-1, 1, -0.3>*trot;
                    kf += ZERO_ROTATION;
                    kf += 2.;
                
                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
    
                    llSleep(5);
                    hearts();
                    llSleep(8);
                    llParticleSystem([]);
                }
                osMessageObject(partner, "BABY|"+PASSWORD+"|"+llGetKey() +"|"+ (string)geneA + "|"+ (string)geneB+ "|" +name);  
            }
            else if (cmd  == "BABY")
            {
                if (pregnantTs<=0)
                {
                    fatherName = llList2String(tk, 5);
                    fatherGene = (integer)llList2String( tk, 3 + (integer)llFrand(2) ) ; // 3 or 4
                    pregnantTs = llGetUnixTime();
                    refresh(llGetUnixTime());
                }
            }
            else if (cmd == "INIT")
            {
               // "INIT|REZ|SF Goat| <0,2,0>|A|B|Goat "+fatherName+" y "+name );
                name = llList2String(tk, 4);
                geneA =  llList2Integer(tk, 2);
                geneB = llList2Integer(tk, 3);
                setGenes();
                //Delete pin
                llSetRemoteScriptAccessPin(0);
                llRemoveInventory("setpin");                
                say(0, "Hello!");
                refresh(llGetUnixTime());

            }
            else if (cmd == "WATER")
            {
                say(1, "Aaah! Refreshing!");
                water = 100.;
                refresh(llGetUnixTime());
            }
            else if (cmd == "FOOD")
            {
                say(1, "Yummy yummy food");
                food = 100.;
                refresh(llGetUnixTime());
    
            }
            else if (cmd == "ADDDAY")
            {
               createdTs -= 86400;
               refresh(llGetUnixTime());
               llOwnerSay("CreatedTs="+(string)createdTs);
            }
            
    }


    sensor(integer n)
    {
        key id = llDetectedKey(0);
        if (status == "WaitMate")
        {
            osMessageObject(id,  "MATEME|"+PASSWORD+"|"+(string)llGetKey());
        }
        else //feeder
        {
                if ( food < 5)
                {
                    osMessageObject(id,   "FEEDME|"+PASSWORD+"|"+ llGetKey() + "|" + (string)FEEDAMOUNT);
                }
    
                if ( water < 5)
                {
                    osMessageObject(id, "WATERME|"+PASSWORD+"|"+ llGetKey() + "|"+ (string)WATERAMOUNT);
                }

        }
    }


    
    no_sensor()
    {
        if (status == "WaitMate")
        {
            say(0, "Uhmm... I don't see a sexy male near me, who am I supposed to mate with?");
        }
        status = "OK";
    }
    



    touch_start(integer n)
    {
        //llOwnerSay((string)llDetectedLinkNumber(0));
        
        integer ts = llGetUnixTime();
        refresh(ts);
        if (llSameGroup(llDetectedKey(0) ) || osIsNpc(llDetectedKey(0)) )
        {
         
           list opts = [];
           opts += "Follow Me";
           opts += "Stop";
           opts += "CLOSE";
           opts +=  "Options";
           
           if (sex == "Female" && !isBaby && pregnantTs ==0 )
               opts +=  "Mate";
           if (!isBaby)
           {
                if (sex == "Female" && AN_HASMILK)
                {
                    if (givenBirth>0 &&  ts - milkTs > MILKTIME) opts += "Milk";
                }
                if (ts - woolTs > WOOLTIME && AN_HASWOOL >0) opts += "Wool";
                if (ts - manureTs > MANURETIME && AN_HASMANURE >0) opts += "Get Manure";
                opts += "Butcher";
           }
           startListen();
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()) );
         
        }
        else
        {
            say(0, "Hello! We are not in the same group");
        }
    }
}
