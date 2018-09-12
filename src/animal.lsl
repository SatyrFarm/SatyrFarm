/*### animal.lsl
 Part of the  SatyrFarm scripts
 This code is provided under a CC-BY-NC license
*/

string AN_NAME = "Animal";
string AN_FEEDER = "SF Animal Feeder";
string AN_BAAH = "Ah";
integer AN_HASGENES = 0;
integer AN_HASMILK = 0;
integer AN_HASWOOL = 0;
integer AN_HASMANURE = 0;
integer LAYS_EGG = 0;     //Reproduces with egg
integer EGG_TIME = 86400; //Time until hatching
integer MATE_INTERVAL= 86400; //how often to be mateable
float CHILD_SCALE = 0.5; // Initial scale as child 
float CHILD_MAX_SCALE = 1.0; // Dont let the child grow beyond this scale
float MALE_SCALE = 1.05;
string MEAT_OBJECT="SF Meat";
string SKIN_OBJECT = "SF Skin";
string MILK_OBJECT="SF Milk";
integer lastEggTs;
string name;

float CHILDHOOD_RATIO=0.15; // How much of life to spend as child

integer VERSION = 1;

list ADULT_MALE_PRIMS = [];
list ADULT_FEMALE_PRIMS = []; // link numbers -   Both sexes
list ADULT_RANDOM_PRIMS = []; //  show randomly
list CHILD_PRIMS = [];        //children only
list colorable = []; 

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

integer RADIUS=5;

integer LIFETIME = 2592000; 

float WATERTIME = 5000. ;
float FEEDTIME  = 5900. ;

integer MILKTIME = 86400 ;
integer MANURETIME = 172800  ;
integer WOOLTIME = 345600 ;

integer PREGNANT_TIME = 432000;

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
vector initpos;

integer lastTs;
integer createdTs;
integer milkTs;
integer woolTs;
integer manureTs;
integer labelType = 0; // 1== short

float food=4.;
float water=4.;

string status = "OK";

string sex;
integer epoch = 0; // 0 = Egg, 1= Baby, 2 = Adult
integer left;
key followUser=NULL_KEY;
integer pregnantTs;
integer givenBirth =0;
string fatherName;
integer age;

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
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
            else if (cmd == "LAYS_EGG") LAYS_EGG = (integer)val;
            else if (cmd == "PREGNANT_TIME") PREGNANT_TIME= (integer)val;
            else if (cmd == "EGG_TIME") EGG_TIME = (integer)val;
            else if (cmd == "MATE_INTERVAL") MATE_INTERVAL = (integer)val;
            else if (cmd == "FEEDAMOUNT") FEEDAMOUNT= (float)val;
            else if (cmd == "WATERAMOUNT") WATERAMOUNT= (float)val;
            else if (cmd == "WATERTIME") WATERTIME= (float)val;
            else if (cmd == "FEEDTIME") FEEDTIME= (float)val;
            else if (cmd == "CHILDHOOD_RATIO") CHILDHOOD_RATIO = (float)val;
            else if (cmd == "CHILD_SCALE") CHILD_SCALE= (float)val;
            else if (cmd == "CHILD_MAX_SCALE") CHILD_MAX_SCALE= (float)val;
            else if (cmd == "MALE_SCALE") MALE_SCALE= (float)val;                
            else if (cmd == "SKIN_OBJECT") SKIN_OBJECT = val;
            else if (cmd == "MEAT_OBJECT") MEAT_OBJECT = val;
            else if (cmd == "MILK_OBJECT") MILK_OBJECT = val;
            else if (cmd == "LIFEDAYS") LIFETIME = (integer)(86400*(float)val);
            else if (cmd == "TOTAL_BABYSOUNDS") TOTAL_BABYSOUNDS = (integer)val;
            else if (cmd == "TOTAL_ADULTSOUNDS") TOTAL_ADULTSOUNDS = (integer)val;
    }
}


loadConfig()
{
    list lines = llParseString2List(osGetNotecard("an_config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
}

loadStateByDesc()
{
    //state by description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "A")
    {
        if ((llList2String(desc, 5) != (string)chan(llGetKey())) ) //Also resets eggs!
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
            food  = llList2Integer(desc, 3);
            epoch = 1; // Assume child         
            createdTs = llList2Integer(desc, 4);
            geneA = llList2Integer(desc, 6);
            geneB = llList2Integer(desc, 7);
            fatherGene = llList2Integer(desc, 8);
            pregnantTs = llList2Integer(desc, 9);
            name = llList2String(desc, 10);
        }
    }
}


setGenes()
{
    integer i;
    string tex;
    
    if (!AN_HASGENES) return;
    if (geneA == geneB)
        tex = "goat"+(string)geneA;
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
    if (LAYS_EGG && epoch ==0)
        llSay(0, str);
    else
    {
        string s = llGetObjectName();
        llSetObjectName(name);
        if (whisper) llWhisper(0, str);
        else llSay(0, str);
        llSetObjectName(s);
        baah();
    }
}

baah()
{
    if (epoch ==1)        llTriggerSound("baby"+(string)(1+(integer)llFrand(TOTAL_BABYSOUNDS)), 1.0);
    else if (epoch == 2)  llTriggerSound("adult"+(string)(1+(integer)llFrand(TOTAL_ADULTSOUNDS)), 1.0);
}

death(integer keepBody)
{
    llSetTimerEvent(0);
    //Prepare for death
    deathFlags = keepBody; //Whether to keep the dead body or die()
    if (MEAT_OBJECT!= "")
        llRezObject(MEAT_OBJECT, llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
    if (SKIN_OBJECT != "")
        llRezObject(SKIN_OBJECT, llGetPos() +<1,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
}

hearts()
{
     llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_FOLLOW_VELOCITY_MASK|PSYS_PART_EMISSIVE_MASK,
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
        llSetLinkPrimitiveParamsFast(llList2Integer(links,i), [PRIM_COLOR, ALL_SIDES, <1,1,1>, vis]);
}

setAlphaByName(string namea, float opacity)
{
    integer i;
    for (i=2; i <= llGetNumberOfPrims();i++)
        if (llGetLinkName(i) == namea)
            llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, ALL_SIDES, <1,1,1>, opacity]);
}

showAlphaSet(integer newEpoch)
{
    if (newEpoch == 0)
    {
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.]); // Hide all
        setAlphaByName("egg_prim", 1.);
    }
    else if (newEpoch == 1)
    {
        //show all but hide adult
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.]);
        setAlphaByName("egg_prim", 0.);
        setAlphaByName("adult_prim", 0.);
        setAlphaByName("adult_male_prim", 0.);
        setAlphaByName("adult_female_prim", 0.);
        setAlphaByName("adult_random_prim", 0.);
        setAlpha(ADULT_FEMALE_PRIMS+ADULT_MALE_PRIMS+ADULT_RANDOM_PRIMS, 0.);// Legacy
        setAlpha(CHILD_PRIMS, 1.);
        setAlphaByName("child_prim", 1.);
    }
    else if (newEpoch == 2)
    {
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.]);
        setAlpha(CHILD_PRIMS+ADULT_RANDOM_PRIMS+ADULT_FEMALE_PRIMS+ADULT_MALE_PRIMS, 0.);
        setAlphaByName("child_prim", 0.);
        setAlphaByName("egg_prim", 0.);
        if (llFrand(1.)<0.5)
        {
            setAlpha(ADULT_RANDOM_PRIMS, 1.);
            setAlphaByName("adult_random_prim", 1.);
        }
        setAlphaByName("adult_prim", 1.);
        if (sex == "Female")
        {
            setAlpha(ADULT_FEMALE_PRIMS, 1.);
            setAlphaByName("adult_female_prim", 1.);
            setAlphaByName("adult_male_prim", 0.);
        }
        else
        {
            setAlpha(ADULT_MALE_PRIMS, 1.);
            setAlphaByName("adult_male_prim", 1.);
            setAlphaByName("adult_female_prim", 0.);
        }
    }
}

setPose(list pose)
{
    integer i;
    float scale;
    if (epoch == 1 ) 
    {
        scale = CHILD_SCALE + (1-CHILD_SCALE) * ((float)(age)/(float)(CHILDHOOD_RATIO*lifeTime));
        if (scale>CHILD_MAX_SCALE) scale = CHILD_MAX_SCALE; 
        if (scale>1) scale = 1.;
    }
    else if (sex=="Male") scale= MALE_SCALE;
    else scale = 1.;
    for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
    {
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, llList2Vector(pose, (i-1)*2-2)*scale, PRIM_ROT_LOCAL, llList2Rot(pose, (i-1)*2-1), PRIM_SIZE, llList2Vector(link_scales, i-2)*scale]);
    }
}


float moveAngle =0;
integer isMoving=0;
move()
{
    if (epoch ==0) return;
    integer i;
    integer rnd = (integer)llFrand(5);
    if (rnd==0)    setPose(rest); 
    else if (rnd==1)    setPose(down); 
    else if (rnd==2)    setPose(eat); 
    else if (IMMOBILE<=0)
    {
        isMoving=7;
        moveAngle = .3-llFrand(.6);
        llSetTimerEvent(.5);
    }
    if (llFrand(1.)< 0.5) baah();
}


refresh(integer ts)
{
    age = (ts-createdTs);
    if (epoch ==0)
    {
        integer pc = llFloor(((float)age / (float)EGG_TIME)*100.);
        if (pc >99)
        {
            epoch = 1; //Egg --> child
            showAlphaSet(epoch);
            llSetTimerEvent(2);
            lastTs = ts;
            createdTs = ts;
            return;
        }
        llSetText(AN_NAME+" Egg\nIncubating..."+(string)pc+"%\n", <1,1,1>, 1.0);
        llSetObjectDesc("A;EGG;"+(string)pc);
        return;
    }
    
    food -= (ts - lastTs)  *(100./FEEDTIME); 
    water -= (ts - lastTs) * (100./WATERTIME); // water consumption rate

    if (food < 5 || water < 5)
    {  
        status ="WaitFood";
        llSensor(AN_FEEDER, "", SCRIPTED, 20, PI);
    }

    float days = (age/86400.);
    string uc = "♂";
    if (sex == "Female") uc = "♀";

    string str =""+name+" "+uc+"\n";
    if (epoch ==1 && days  > (lifeTime*CHILDHOOD_RATIO/86400.))
    {
        epoch = 2; // Child --> adult
        FEEDAMOUNT  = 2.*FEEDAMOUNT;
        WATERAMOUNT = 2.*WATERAMOUNT;
        showAlphaSet(epoch);
    }

    if (food < 0 && water <0) say(0, AN_BAAH+", I'm hungry and thirsty!");
    else if (food < 0) say( 0,AN_BAAH+", I'm hungry!");
    else if (water < 0) say( 0, AN_BAAH+", I'm thirsty!");

    str += ""+(string)((integer)days)+" days old ";
    if (epoch == 1) str += "(Child)\n";
    else 
    {
        str += "\n";
        float p = 100.*(ts - milkTs)/MILKTIME;
        if (p > 100) p = 100;

        if (AN_HASMILK && sex == "Female")
        {
            if (LAYS_EGG==1)
                str += "Eggs: "+(string)((integer)p)+"%\n";
            else if (givenBirth>0)
                str += "Milk: "+(string)((integer)p)+"%\n";
        }
        
        p = 100.*(ts - woolTs)/WOOLTIME;
        if (p > 100) p = 100;
        if (AN_HASWOOL)
            str += "Wool: "+(string)((integer)p)+"%\n";

    }

    if (age > lifeTime || food < -20000 || water < -20000)
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
                if (LAYS_EGG)
                {
                    say(0, "I laid an egg!");
                    lastEggTs= ts;
                }
                else
                {
                    say(0, "I had a baby!");
                    givenBirth++;
                }
            }
            else str += "PREGNANT! ("+(string)((integer)(perc*100))+"%)\n";
        }
        vector color = <1,1,1>;
        if (food<0)
        {
            str += "HUNGRY!\n";
            color = <1,0,0>;
        }
        else if (food<50)
            str += "Food: "+(string)((integer)food)+"%\n";

        if (water<0)
        {
            str += "THIRSTY!\n";
            color = <1,0,0>;
        }
        else if (water <50)
            str += "Water: "+(string)((integer)water)+"%\n";
        
        if (labelType == 1)
            llSetText(name , color, 1.0);
        else
            llSetText(str , color, 1.0);
    }

    integer scode=0;
    if (sex == "Female") scode=1;
    llSetObjectDesc("A;"+(string)scode+";"+(string)llRound(water)+";"+(string)llRound(food)+";"+(string)createdTs+";"+(string)chan(llGetKey())+";"+(string)geneA+";"+(string)geneB+";"+(string)fatherGene+";"+(string)pregnantTs+";"+name+";");
}

list getNC(string ncname)
{
    list lst = llParseString2List(osGetNotecard(ncname), ["|"], []);
    return lst; 
}


default
{
    state_entry()
    {
        llSetText("",<1,1,1>, 1.);
        if (osRegexIsMatch(llGetObjectName(), "(Update|Rezz)"))
        {
            llSay(0, "Sleeping");
            llSetScriptState(llGetScriptName(), FALSE); // Dont run in the rezzer
            return;
        }
        rest =  getNC("rest");
        down = getNC("down");
        eat = getNC("eat");
        walkl = getNC("walkl");
        walkr = getNC("walkr");
        link_scales = getNC("scales");
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        
        loadConfig();
        name = AN_NAME;
        llSetObjectName("SF "+AN_NAME);
         
        //Set Defaults
        llSetRot(ZERO_ROTATION);
        llSetLinkColor(LINK_ALL_OTHERS, <1, 1,1>, ALL_SIDES);
        if (llFrand(1.) < 0.5) sex = "Female";
        else sex = "Male";
        geneA = 1+ (integer)llFrand(3);
        geneB = 1+ (integer)llFrand(3);
        lastTs = createdTs = llGetUnixTime()-10;
        initpos = llGetPos();
        if (LAYS_EGG) epoch =0;
        else epoch = 1;
        lifeTime = (integer) ( (float)LIFETIME*( 1.+llFrand(.1)) );
        
        //Load state after defaults
        loadStateByDesc();
        setGenes();
        setPose(rest);
        showAlphaSet(epoch);
        llSetTimerEvent(2);
    }
    
    on_rez(integer n)
    {
        listener = -1;
        lastTs = llGetUnixTime();
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
            llGiveInventory(id, "SF "+AN_NAME);
            osMessageObject(id,   "INIT|"+PASSWORD+"|"+babyParams);
        }
        else
        {
            osMessageObject(id, "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
            if (llKey2Name(id) == MEAT_OBJECT) deathFlags = deathFlags|2;
            if (llKey2Name(id) == SKIN_OBJECT) deathFlags = deathFlags|4;
            if ((MEAT_OBJECT=="" || (deathFlags&2)) && (SKIN_OBJECT=="" || (deathFlags&4)))
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
        if (isMoving>0)
        {
            if (isMoving==1)
            {
                setPose(rest);
                llSetTimerEvent(11);
            }
            else
            {
                vector cp = llGetPos();
                vector v = cp + <.4, 0, 0>*(llGetRot()*llEuler2Rot(<0,0,moveAngle>));
                v.z = cp.z;
                if ( llVecDist(v, initpos)< RADIUS)
                {
                    if (isMoving%2==0) setPose(walkl);
                    else setPose(walkr);
                    llSetPrimitiveParams([PRIM_POSITION, v, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,moveAngle>) ]);
                }
                else
                    llSetPrimitiveParams([PRIM_POSITION, cp, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,PI/2>) ]);
            }
            isMoving--;
            return;
        }
        
        
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
                    if (left)   setPose(walkl);
                    else    setPose(walkr);
                    if (llFrand(1.)< 0.1) baah();
                    initpos = fpos;
                }
            }
        }
        
        integer ts = llGetUnixTime();
        if (ts - lastTs>10)
        {
            refresh(ts);           
            if (epoch == 0)  llSetTimerEvent(200);
            else
            {
                if (status == "DEAD") 
                {
                    llSetTimerEvent(0);
                    return;
                }
                else if (followUser == NULL_KEY)
                {
                    llSetTimerEvent(25+ (integer)llFrand(20));
                    move();
                }
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
            
            if (epoch ==2)
                opts += "Butcher";
            opts += "Help";
            llDialog(id, "Select", opts, chan(llGetKey()) );
        }
        else if (m == "Help")
        {
            string str = "I am a "+AN_NAME+" and i eat from "+AN_FEEDER+". ";
            if (AN_HASMILK) str += "The females of my species give "+MILK_OBJECT+" every "+(string)llRound(MILKTIME/3600)+" hours. ";
            if (AN_HASWOOL) str += "Adults give Wool every "+(string)llRound(WOOLTIME/3600)+" hours. ";
            if (AN_HASMANURE) str += "Adults give Manure every "+(string)llRound(MANURETIME/3600)+" hours. ";
            str += "Pregnancy lasts "+(string)(PREGNANT_TIME/86400)+" days. On average, we live "+(string)(LIFETIME/86400)+" days. ";
            str += "Visit http://satyrfarm.github.io for more information";
            say(0, str);
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
            followUser =NULL_KEY;
            llStopSound();
            setPose(down);
            initpos = llGetPos();
            llSetTimerEvent(5);
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
            refresh(llGetUnixTime());
        }
        else if (m == "Milk" || m == "Get Eggs")
        {
            if (sex == "Female" && AN_HASMILK)
            {
                say(0, "Here is your "+MILK_OBJECT);
                llRezObject(MILK_OBJECT, llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
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
        else if (m == "Wool" && AN_HASWOOL)
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
    }
    
    dataserver(key kk, string m)
    {
        list tk = llParseStringKeepNulls(m , ["|"], []);
        if (llList2String(tk,1) != PASSWORD)  { llSay(0, "Password mismatch"); return;  } 
        
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
        else if (cmd =="SETCONFIG")
        {
            if (llGetOwnerKey(kk) == llGetOwner())
                setConfig(llList2String(tk,2));
        }
        else if (cmd == "MATEME" ) //Male part
        {
                if (epoch != 2)
                {
                    say(0,  "I am a child, you pervert...");
                    return;
                }
                else if (sex != "Male")
                {
                    say(0, "Sorry, I'm not a lesbian");
                    return;
                }
                
                key partner = llList2Key(tk,2);
                
                list ud =llGetObjectDetails(partner, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
                llSetKeyframedMotion( [], []);
                llSleep(.2);
                list kf;
                vector mypos = llGetPos();
                vector v = llList2Vector(ud, 1) + <-.3,  .0, 0.3> * llList2Rot(ud,2);
                
                rotation trot  =  llList2Rot(ud,2);
                vector vn = llVecNorm(v  - mypos );
                vn.z=0;

                kf += ZERO_VECTOR;
                kf += (trot/llGetRot()) ;
                kf += .4;
                kf += v- mypos;
                kf += ZERO_ROTATION;
                kf += 3;
                kf += ZERO_VECTOR;
                kf += llEuler2Rot(<0,-.3,0>);
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
                kf += llEuler2Rot(<0, .3, 0>);
                kf += .3;
                kf += <-1, 1, -0.3>*trot;
                kf += ZERO_ROTATION;
                kf += 2.;
            
                llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                llSleep(5);
                hearts();
                llSleep(8);
                llParticleSystem([]);
                osMessageObject(partner, "BABY|"+PASSWORD+"|"+(string)llGetKey() +"|"+ (string)geneA + "|"+ (string)geneB+ "|" +name);  
        }
        else if (cmd  == "BABY") //Female part
        {
            if (pregnantTs<=0)
            {
                fatherName = llList2String(tk, 5);
                fatherGene = (integer)llList2String( tk, 3 + (integer)llFrand(2) ) ; // 3 or 4                    
                if (LAYS_EGG)
                {
                    //Force an egg
                    PREGNANT_TIME=0;
                    pregnantTs = llGetUnixTime()-100;
                }
                else
                    pregnantTs = llGetUnixTime();
                llSleep(2);
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
            if (LAYS_EGG==0)
                say(0, "Hello!");
            llSetTimerEvent(2);
        }
        else if (cmd == "WATER")
        {
            say(1, "Aaah, refreshing!");
            water = 100.;
            refresh(llGetUnixTime());
        }
        else if (cmd == "FOOD")
        {
            say(1, "Yum yum, food!");
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
            llSetTimerEvent(15); // dont move
            osMessageObject(id,  "MATEME|"+PASSWORD+"|"+(string)llGetKey());
        }
        else //feeder
        {
            string desc;
            if ( food < 5)
            {
                integer level = 0;
                integer i;
                for (i = 0; level < FEEDAMOUNT && i < n; i++)
                {
                    desc = llList2String(llGetObjectDetails(llDetectedKey(i), [OBJECT_DESC]), 0);
                    level = llList2Integer(llParseString2List(desc, [";"], []), 3);
                }
                --i;
                if (i == n) i = 0;
                osMessageObject(llDetectedKey(i),   "FEEDME|"+PASSWORD+"|"+ (string)llGetKey() + "|" + (string)FEEDAMOUNT);
            }

            if ( water < 5)
            {
                integer level = 0;
                integer i;
                for (i = 0; level < WATERAMOUNT && i < n; i++)
                {
                    desc = llList2String(llGetObjectDetails(llDetectedKey(i), [OBJECT_DESC]), 0);
                    level = llList2Integer(llParseString2List(desc, [";"], []), 2);
                }
                --i;
                if (i == n) i = 0;
                osMessageObject(llDetectedKey(i), "WATERME|"+PASSWORD+"|"+ (string)llGetKey() + "|"+ (string)WATERAMOUNT);
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
        integer ts = llGetUnixTime();
        refresh(ts);
        if (epoch ==0)
            llSay(0, "Hello! I 'm just an egg");
        else if (llSameGroup(llDetectedKey(0) ) || osIsNpc(llDetectedKey(0)) )
        {
         
           list opts = [];
           opts += "Follow Me";
           opts += "Stop";
           opts += "CLOSE";
           opts +=  "Options";
           
           if (sex == "Female" && epoch == 2)
           {
               if ( (LAYS_EGG==1 && ts> lastEggTs+MATE_INTERVAL) || (LAYS_EGG==0&& pregnantTs ==0) )
                   opts +=  "Mate";
           }
           if (epoch == 2)
           {   
               if (sex == "Female" && AN_HASMILK)
               {
                    if (  ts - milkTs > MILKTIME) 
                    {
                        if (LAYS_EGG==1) opts += "Get Eggs";
                        else if (givenBirth>0) opts += "Milk";
                    }
               }
               if (ts - woolTs > WOOLTIME && AN_HASWOOL >0) opts += "Wool";
               if (ts - manureTs > MANURETIME && AN_HASMANURE >0) opts += "Get Manure";
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

