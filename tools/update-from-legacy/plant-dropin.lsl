//### plant-dropin.lsl
/**
This helper script provides the Update-API for old fields.
Insert this script in your old fields, then use the update box.
**/

string PASSWORD = "farm";
integer WATER = 0;
integer WOOD = 0;
integer PERCENT = 0;
integer ISTREE = 0;
integer LIFEDAYS = 2;
integer WATERTIMES = 2;
integer AUTOREPLANT = 0;
integer WOODTIMES = 1;
string STATUS = "";
string PLANT = "";
string PRODUCT = "";
string myPlants = "";
string myProducts = "";

list PLANTS = ["Orange Tree","Apple Tree","Cherry Tree","Lemon Tree","Coffee Tree","Cocoa Tree","Corn","Grain","Hay","Carrots","Eggplants","Onions","Peppers","Pot","Potatoes","Strawberries","Sugar Cane","Tomatoes", "Olive Tree", "Rice", "Grapevine"];
list PRODUCTS = ["SF Oranges","SF Apples","SF Cherries","SF Lemons","SF Coffee Beans","SF Cocoa Beans","SF Corn","SF Grain","SF Hay","SF Carrots","SF Eggplants","SF Onions","SF Peppers","SF Pot","SF Potatoes","SF Strawberries","SF Sugar Cane","SF Tomatoes", "SF Olives", "SF Rice", "SF Grapes"];
string plantsTree = "Orange Tree,Apple Tree,Cherry Tree,Lemon Tree,Coffee Tree,Cocoa Tree";
string productsTree = "SF Oranges,SF Apples,SF Cherries,SF Lemons,SF Coffee Beans,SF Cocoa Beans";
string plantsSmallField = "Carrots,Eggplants,Onions,Peppers,Pot,Potatoes,Strawberries,Sugar Cane,Tomatoes";
string productsSmallField = "SF Carrots,SF Eggplants,SF Onions,SF Peppers,SF Pot,SF Potatoes,SF Strawberries,SF Sugar Cane,SF Tomatoes";
string plantsField = "Corn,Grain,Hay";
string productsField = "SF Corn, SF Grain,SF Hay";

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


default
{
    state_entry()
    { 
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1)
        {
            string me = llGetScriptName();
            llOwnerSay("Script " + me + " went to sleep inside Updater.");
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        llSetRemoteScriptAccessPin(0);
        llOwnerSay("Prepare product for Update");
        //product list by name
        string name = llKey2Name(llGetKey());
        if (name == "SF Small Field")
        {
            myPlants = plantsSmallField;
            myProducts = productsSmallField;
        }
        else if (name == "SF Square Field")
        {
            myPlants = plantsField;
            myProducts = productsField;
        }
        else if (name == "SF Tree" || name == "SF Cherry Tree" || name == "SF Lemon Tree" || name == "SF Orange Tree" || name == "SF Apple Tree")
        {
            myPlants = plantsTree;
            myProducts = productsTree;
            LIFEDAYS = 3;
            WATERTIMES = 4;
            AUTOREPLANT = 1;
            WOODTIMES = 1;
            ISTREE = 1;
        }
        else if (name == "SF Olive Tree")
        {
            myPlants = "Olive Tree";
            myProducts = "SF Olives";
            PLANT = "Olive Tree";
            PRODUCT = "SF Olives";
            LIFEDAYS = 4;
            WATERTIMES = 4;
            AUTOREPLANT = 1;
            WOODTIMES = 1;
            ISTREE = 1;
        }
        else if (name == "SF Rice Field")
        {
            myPlants = "Rice";
            myProducts = "SF Rice";
            PLANT = "Rice";
            PRODUCT = "SF Rice";
        }
        else if (name == "SatyrFarm Grapevine")
        {
            WATERTIMES = 4;
            LIFEDAYS = 4;
            ISTREE = 1;
            WOODTIMES = 1;
            myPlants = "Grapevine";
            myProducts = "SF Grapes";
            AUTOREPLANT = 1;
        }
        else
        {
            llOwnerSay("NOPE NOPE NOPE NOPE NOPE NOPE!!!");
            llRemoveInventory(llGetScriptName());
        }
        //Parse Hovertext
        string text = llList2String(llGetPrimitiveParams([PRIM_TEXT]), 0);
        list lines = llParseString2List(text, ["\n"], []);
        integer c = llGetListLength(lines);
        while (c--)
        {
            list line = llParseString2List(llList2String(lines, c), [" ", "%", "(", ")"], []);
            string first = llList2String(line, 0);
            if (first == "Water:")
            {
                WATER = llList2Integer(line, 1);
           }
            else if (first == "Status:")
            {
                STATUS = llList2String(line, 1);
                PERCENT = llList2Integer(line, 2);
            }
            else if (first == "Wood:")
            {
                WOOD = llList2Integer(line, 1);
            }
            else if (first != "" && first != "NEEDS")
            {
                PLANT = first;
            }
        }
        if (STATUS != "")
        {
            //Get product
            if (name == "SF Cherry Tree" || name == "SF Lemon Tree" || name == "SF Orange Tree" || name == "SF Apple Tree" || name == "SF Olive Tree")
            {
                PLANT = llGetSubString(name, 3, -1);
            }
            else if (name == "SatyrFarm Grapevine")
            {
                PLANT = "Grapevine";
            }
            if (PLANT == "")
            {
                llOwnerSay("NOPE NOPE NOPE NOPE NOPE NOPE!!!");
                llRemoveInventory(llGetScriptName());
            }
            PRODUCT = llList2String(PRODUCTS, llListFindList(PLANTS, [PLANT]));
            //Description
            integer LIFETIME = 86400 * LIFEDAYS;
            integer statusDur = LIFETIME;
            if (STATUS == "New")
                statusDur = LIFETIME / 3;
            integer statusLeft = (integer)((100 - PERCENT) * statusDur / 100);
            llSetObjectDesc("T;"+PRODUCT+";"+STATUS+";"+(string)(statusLeft)+";"+(string)llRound(WATER)+";"+(string)llRound(WOOD)+";"+PLANT+";"+(string)chan(llGetKey())+";1");
        }
        else
        {
            llSetObjectDesc("");
        }
        //change name for trees
        if (name == "SF Cherry Tree" || name == "SF Lemon Tree" || name == "SF Orange Tree" || name == "SF Apple Tree")
        {
            llSetObjectName("SF Tree");
        }
        //Config Notecard
        string config = "";
        config += "HAS_WOOD="+(string)ISTREE+"\n";
        config += "PLANTLIST="+(string)myPlants+"\n";
        config += "PRODUCTLIST="+(string)myProducts+"\n";
        config += "LIFEDAYS="+(string)LIFEDAYS+"\n";
        config += "WATER_TIMES="+(string)WATERTIMES;
        if (ISTREE)
        {
            config += "\nWOOD_TIMES="+(string)WOODTIMES;
        }
        if (AUTOREPLANT)
        {
            config += "\nAUTOREPLANT="+(string)AUTOREPLANT;
        }
        //Remove everything except myself
        integer len = llGetInventoryNumber(INVENTORY_ALL);
        while (len--)
        {
            string item = llGetInventoryName(INVENTORY_ALL, len);
            if (item != llGetScriptName())
                llRemoveInventory(item);
        }
        //write notecards
        osMakeNotecard("sfp", PASSWORD);
        osMakeNotecard("config", config);
        //done preparing
        state ready;
    }
}


state ready
{
    state_entry()
    {
        llSetText("Ready For Update!", <1,0,0>, 1.0);
        llSay(0, "Ready for update.");
    }

    dataserver(key k, string m)
    {
        list cmd = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);
        //for updates
        if (command == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|" + (string)llGetKey() + "|0||";
            osMessageObject(llList2Key(cmd, 2), answer);
        }
        else if (command == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, "Reject Update, because you are not my Owner.");
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(cmd, 3);
            list lRemoveItems = llParseString2List(sRemoveItems, [","], []);
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item != me && llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            llSay(0, "Removing myself for update.");
            llRemoveInventory(me);
        }
        //
    }
}
