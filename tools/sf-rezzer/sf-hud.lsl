//### sf-hud.lsl
//HUD for Rezzing Satyr Farm Itemsd
integer gi_buttonOffset = 8;
integer gi_frontFace = 4;
integer gi_linkBack = 6;
integer gi_linkForward = 7;
integer gi_linkBuy = 3;
integer gi_linkSell = 4;
integer gi_linkTab = 5;
integer gi_linkDesc = 2;
integer gi_itemCount;
integer gi_curPage;
string gs_selectedItem;
integer gi_selectedPrice;
integer gi_balance = 200;
list gl_sellprices;
//Item Button List
list gl_ident;
list gl_prices;
//Variables for Updater
string PASSWORD;
list ADDITIONS = [];
list ITEMIGNORE = [];
list myItems;
//Sell Menu
integer listener = -1;
integer startOffset = 0;
key gk_user;
list gl_buttons = [];
list gl_selitems = [];
string gs_lookingFor;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

updateBalance()
{
    llSetLinkPrimitiveParamsFast(gi_linkSell, [PRIM_TEXT, "Balance: \n" + (string)gi_balance, <0.0, 0.0, 0.0>, 1.0]);
    llSetObjectDesc((string)gi_balance);
}

multiPageSellMenu()
{
    integer ch = chan(llGetKey());
    integer l = llGetListLength(gl_buttons);
    if (startOffset >= l)
    {
        startOffset = 0;
    }
    list its = llList2List(gl_buttons, startOffset, startOffset + 9);
    if (l >= 12)
    {
        l = llGetListLength(its);
        its += [">>"];
    }
    string message = "Select item to sell:\n";
    while (l--)
    {
        string name = llList2String(its, l);
        integer pos = llListFindList(gl_sellprices, [name]) + 1;
        message += name + ": " + llList2String(gl_sellprices, pos) + "\n";
    }
    if (listener == -1)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    llSetTimerEvent(300);
    llDialog(gk_user, message, ["CLOSE"] + its, ch);
}

drawButtons()
{
    integer i_pageCount = llFloor((gi_itemCount - 1) / 8);
    if (gi_curPage > i_pageCount)
    {
        gi_curPage = 0;
    }
    if (gi_curPage < 0)
    {
        gi_curPage = i_pageCount;
    }

    integer a = 0;
    integer i_item;
    string s_item;
    string s_texture;
    while (a < 8)
    {
        i_item = gi_curPage * 8 + a;
        if (i_item < gi_itemCount)
        {
            s_item = llList2String(gl_ident, i_item);
            s_texture = "btns-" + s_item;
            if (llGetInventoryType(s_texture) != INVENTORY_TEXTURE)
            {
                s_texture = NULL_KEY;
            }
            llSetLinkPrimitiveParamsFast(a + gi_buttonOffset,      [PRIM_TEXTURE, gi_frontFace, s_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
            //llSetLinkPrimitiveParamsFast(a + gi_buttonOffset,      [PRIM_TEXTURE, gi_frontFace, s_item, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0, PRIM_TEXT, s_item, <0.0, 0.0, 0.0>, 1.0]);
        }
        else
        {
            llSetLinkPrimitiveParamsFast(a + gi_buttonOffset,      [PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 0.0]);
            //llSetLinkPrimitiveParamsFast(a + gi_buttonOffset,      [PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 0.0, PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
        }
        ++a;
    }
}

loadItemList(string ncname)
{
    gs_selectedItem = "";
    llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_COLOR, gi_frontFace, <0.0, 0.0, 0.0>, 0.5]);
    llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.5, 1.0, 0.0>, <-0.25, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
    llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
    list items = llParseString2List(osGetNotecard(ncname), ["\n", ":"] ,[]);
    gl_ident = llList2ListStrided(items, 0, -1, 2);
    gl_prices = llList2ListStrided(llDeleteSubList(items,0,0), 0, -1, 2);
    gi_itemCount = llGetListLength(gl_ident);
    drawButtons();
}

string itemsToReplace(string sItems, key kObject)
{
    list lReplace = [];
    integer found_add = llListFindList(ADDITIONS, [llKey2Name(kObject)]) + 1;
    if (found_add)
    {
        lReplace += llParseString2List(llList2String(ADDITIONS, found_add), [","], []);
    }
    lReplace += ["sfp"];
    list lItems = llParseString2List(sItems, [","], []);
    integer i = llGetListLength(lItems);
    integer c;
    for (c = 0; c < i; c++)
    {
        string item = llList2String(lItems, c);
        if (llListFindList(myItems, [item]) != -1 && llListFindList(ITEMIGNORE, [item]) == -1 && llListFindList(lReplace, [item]) == -1)
        {
            lReplace += [item];
        }
    }
    lReplace += ["mover"];
    return llDumpList2String(lReplace, ",");
}


default
{
    state_entry()
    {
        //config notecards
        if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("sellprices") == INVENTORY_NONE)
        {
            llSay(0, "No version or password or sellprices notecard in inventory! Can't work like that.");
        }
        PASSWORD = osGetNotecardLine("sfp", 0);
        gl_sellprices = llParseString2List(osGetNotecard("sellprices"), ["\n", "="], [""]);
        if (llGetInventoryType("additions") != INVENTORY_NONE)
        {
            ADDITIONS = [];
            list addnc = llParseString2List(osGetNotecard("additions"), ["\n"], []);
            integer c = llGetListLength(addnc);
            while (c--)
            {
                ADDITIONS += llParseStringKeepNulls(llList2String(addnc, c), [":"], []);
            }
        }
        if (llGetInventoryType("itemignore") != INVENTORY_NONE)
        {
            ITEMIGNORE = llParseString2List(osGetNotecard("itemignore"), ["\n"], []);
        }
        //own items
        myItems = [];
        integer len = llGetInventoryNumber(INVENTORY_ALL);
        while (len--)
        {
            myItems += [llGetInventoryName(INVENTORY_ALL, len)];
        }
        //get Balance
        gi_balance = (integer)llGetObjectDesc();
        updateBalance();
        //check textures in inventory and populate lists
        integer i_itemCount = llGetInventoryNumber(INVENTORY_TEXTURE);
        gl_ident = [];
        integer a = 0;
        string s_item;
        string s_ident;
        string s_prefix;
        integer b;
        while (a < i_itemCount)
        {
            s_item = llGetInventoryName(INVENTORY_TEXTURE, a);
            b = llSubStringIndex(s_item, "-");
            s_prefix = llGetSubString(s_item, 0, b - 1);
            s_ident = llGetSubString(s_item, b + 1, -1);
            if (s_prefix == "btns")
            {
                gl_ident += [s_ident];
            }
            ++a;
        }
        gi_curPage = 0;
        gi_itemCount = llGetListLength(gl_ident);
        //load items from notecards
        loadItemList("farmitems");
        //done
        state ready;
    }
}

state ready
{
    state_entry()
    {
        //draw main buttons
        gs_selectedItem = "";
        llSetLinkPrimitiveParamsFast(gi_linkForward, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.0625, 0.125, 0.0>, <0.46875, 0.4375, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkBack, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.0625, 0.125, 0.0>, <0.40625, 0.4375, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.250, 0.125, 0.0>, <0.125, 0.4375, 0.0>, 0.0]);
        llSetLinkPrimitiveParamsFast(gi_linkSell, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.250, 0.125, 0.0>, <0.125, -0.4375, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkTab, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.500, 0.25, 0.0>, <0.250, 0.00, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.5, 1.0, 0.0>, <-0.25, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_COLOR, gi_frontFace, <0.0, 0.0, 0.0>, 0.5]);
        llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
    }

    listen(integer c, string nm, key id, string m)
    {
        if (m == ">>")
        {
            startOffset += 10;
            multiPageSellMenu();
        }
        else if (m == "CLOSE")
        {
            llListenRemove(listener);
            gl_selitems = [];
            gl_buttons = [];
            listener = -1;
        }
        else if (llListFindList(gl_buttons, [m]) != -1)
        {
            gs_lookingFor = m;
            llSensor("SF " + m, "", SCRIPTED, 10, PI);
            multiPageSellMenu();
        }
    }

    sensor(integer n)
    {
        if (gs_lookingFor == "all")
        {
            gl_buttons = [];
            while (n--)
            {
                string name = llGetSubString(llKey2Name(llDetectedKey(n)), 3, -1);
                if (llListFindList(gl_sellprices, [name]) != -1 && llListFindList(gl_buttons, [name]) == -1)
                {
                    gl_buttons += [name];
                }
            }
            if (gl_buttons == [])
            {
                llSay(0, "No sellable items found nearby");
            }
            else
            {
                multiPageSellMenu();
            }
            return;
        }
        //get first product that isn't already selected and has enough percentage
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (llListFindList(gl_selitems, [obj]) == -1 && (have_percent == 100 || have_percent == 0))
            {
                ready_obj = llDetectedKey(c);
                gl_selitems += [obj];
            }
        }
        //--
        if (ready_obj == NULL_KEY)
        {
            llSay(0, "Error! Full "+gs_lookingFor+" not found nearby. You must bring it near me!");
            return;
        }
        gl_selitems += [ready_obj];
        llSay(0, "Found "+gs_lookingFor+", emptying...");
        osMessageObject(ready_obj, "DIE|"+(string)llGetKey());
    }

    dataserver(key k, string m)
    {
        list cmd = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(cmd,1) != PASSWORD ) { llSay(0, "Bad password"); return; } 
        string item = llList2String(cmd,0);

        integer i;
        for (i=0; i < llGetListLength(gl_sellprices); i++)
        {
            if (llToUpper(llList2String(gl_sellprices, i)) ==  item)
            {
                gi_balance += llList2Integer(gl_sellprices, i + 1);
                updateBalance();
                return;
            }
        }
    }

    no_sensor()
    {
        llOwnerSay(gs_lookingFor+" not found nearby!");
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(listener != -1)
        {
            llListenRemove(listener);
            listener = -1;
            gl_selitems = [];
            gl_buttons = [];
        }
    }

    touch_start(integer num)
    {
        if (!llSameGroup(llDetectedKey(0)) && !osIsNpc(llDetectedKey(0)))
        {
            llSay(0, "We are not in the same group");
            return;
        }
        integer link = llDetectedLinkNumber(0);
        if (link == gi_linkBack)
        {
            --gi_curPage;
            drawButtons();
        }
        else if (link == gi_linkForward)
        {
            ++gi_curPage;
            drawButtons();
        }
        else if (link == gi_linkTab)
        {
            vector touched = llDetectedTouchST(0);
            if (touched.x < 0.5)
            {
                llSetLinkPrimitiveParamsFast(gi_linkTab, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.500, 0.25, 0.0>, <0.250, 0.00, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
                loadItemList("farmitems");
            }
            else
            {
                llSetLinkPrimitiveParamsFast(gi_linkTab, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.500, 0.25, 0.0>, <0.250, 0.25, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
                loadItemList("animalitems");
            }
        }
        else if (link == gi_linkSell)
        {
            gk_user = llDetectedKey(0);
            gs_lookingFor = "all";
            llSensor("", "", SCRIPTED, 10, PI);
        }
        else if (link >= gi_buttonOffset && link < gi_buttonOffset + 8)
        {
            integer i_item = gi_curPage * 8 + link - gi_buttonOffset;
            if (i_item >= gi_itemCount)
            {
                llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.5, 1.0, 0.0>, <-0.25, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
                llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_COLOR, gi_frontFace, <0.0, 0.0, 0.0>, 0.5]);
                llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
                gs_selectedItem = "";
                return;
            }
            gs_selectedItem = llList2String(gl_ident, i_item);
            gi_selectedPrice = llList2Integer(gl_prices, i_item);
            vector color;
            if (gi_balance >= gi_selectedPrice)
            {
                color = <0.180, 0.800, 0.251>;
                llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
            }
            else
            {
                color = <1.0, 0.0, 0.0>;
                llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_COLOR, gi_frontFace, <0.0, 0.0, 0.0>, 0.5]);
            }
            llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_TEXT, gs_selectedItem + "\nPrice: " + (string)gi_selectedPrice, color, 1.0]);
            string button = "btnb-" + gs_selectedItem;
            if (llGetInventoryType(button) == INVENTORY_NONE)
            {
                button = "btns-" + gs_selectedItem;
            }
            llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, button, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
        }
        else if (link == gi_linkBuy && gs_selectedItem != "" && gi_selectedPrice <= gi_balance)
        {
            gi_balance -= gi_selectedPrice;
            updateBalance();
            state rezz;
        }
    }

   changed(integer change)
   {
       if (change & CHANGED_INVENTORY)
       {
           llResetScript();
       }
   }

   on_rez(integer num)
   {
       llResetScript();
   }
}


state rezz
{
    state_entry()
    {
        llSetLinkPrimitiveParamsFast(gi_linkBuy, [PRIM_COLOR, gi_frontFace, <1.0, 1.0, 0.0>, 1.0]);
        llSay(0, "Rezzing " + gs_selectedItem);
        llRezObject(gs_selectedItem, llGetPos() + <2.5,0.0,1.0>*llGetRot(), <0.0,0.0,0.0>, <0.0,0.0,0.0,1.0>, 0);
    }

    state_exit()
    {
        llSay(0, "Object is ready :)");
        llSetTimerEvent(0.0);
    }

    object_rez(key id)
    {
        llSleep(3.0);
        osMessageObject(id, "VERSION-CHECK|" + PASSWORD + "|" + (string)llGetKey());
        llSetTimerEvent(20.0);
    }

    timer()
    {
        state ready;
    }

    dataserver(key k, string m)
    {
        list cmd = llParseString2List(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);

        if (command == "VERSION-REPLY")
        {
            string repstr = itemsToReplace(llList2String(cmd,4), llList2Key(cmd, 2));
            if (repstr != "")
            {
                llSay(0, "Preparing rezzed item.");
                osMessageObject(llList2Key(cmd, 2), "DO-UPDATE|"+PASSWORD+"|"+(string)llGetKey()+"|"+repstr);
                llSetTimerEvent(20.0);
                return;
            }
            state ready;
        }
        else if (command == "DO-UPDATE-REPLY")
        {
            llSleep(2.0);
            key kobject = llList2Key(cmd, 2);
            integer ipin = llList2Integer(cmd, 3);
            list litems = llParseString2List(llList2String(cmd, 4), [","], []);
            integer d = llGetListLength(litems);
            integer c;
            for (c = 0; c < d; c++)
            {
                string sitem = llList2String(litems, c);
                if (llListFindList(ITEMIGNORE, [sitem]) == -1)
                {
                    integer type = llGetInventoryType(sitem);
                    if (type == INVENTORY_SCRIPT)
                    {
                        llRemoteLoadScriptPin(kobject, sitem, ipin, TRUE, 0);
                    }
                    else if (type != INVENTORY_NONE)
                    {
                        llGiveInventory(kobject, sitem);
                    }
                }
            }
            llSay(0, "Prepared: \n    " + llList2String(cmd,4));
            osMessageObject(kobject, "INIT|" + PASSWORD);
            state ready;
        }
    }
}
