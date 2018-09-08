//### sf-hud.lsl
//HUD for Rezzing Satyr Farm Items
integer gi_buttonOffset = 6;
integer gi_frontFace = 4;
integer gi_linkBack = 4;
integer gi_linkForward = 5;
integer gi_linkApply = 3;
integer gi_linkDesc = 2;
integer gi_itemCount;
integer gi_curPage;
string gs_selectedItem;
//Item Button List
list gl_ident;
//Variables for Updater
integer VERSION;
string PASSWORD;
list ADDITIONS = [];
list ITEMIGNORE = [];
list myItems;

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

string itemsToReplace(string sItems, key kObject)
{
    list lReplace = [];
    integer found_add = llListFindList(ADDITIONS, [llKey2Name(kObject)]) + 1;
    if (found_add)
    {
        lReplace += llParseString2List(llList2String(ADDITIONS, found_add), [","], []);
    }
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
    return llDumpList2String(lReplace, ",");
}


default
{
    state_entry()
    {
        //config notecards
        if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("version") == INVENTORY_NONE)
        {
            llSay(0, "No verion or password notecard in inventory! Can't work like that.");
        }
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        VERSION = (integer)llStringTrim(osGetNotecard("version"), STRING_TRIM);
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
        //draw item selection buttons
        drawButtons();
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
        llSetLinkPrimitiveParamsFast(gi_linkForward, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.128, 0.128, 0.0>, <0.435, 0.375, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkBack, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.128, 0.128, 0.0>, <0.3125, 0.375, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkApply, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.250, 0.128, 0.0>, <0.125, 0.4, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 0.0, 0.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.5, 1.0, 0.0>, <-0.25, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
    }

    touch_start(integer num)
    {
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
        else if (link >= gi_buttonOffset && link < gi_buttonOffset + 8)
        {
            integer i_item = gi_curPage * 8 + link - gi_buttonOffset;
            if (i_item >= gi_itemCount)
            {
                llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.5, 1.0, 0.0>, <-0.25, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
                gs_selectedItem = "";
                return;
            }
            gs_selectedItem = llList2String(gl_ident, i_item);
            //do something here
            string button = "btnb-" + gs_selectedItem;
            if (llGetInventoryType(button) == INVENTORY_NONE)
            {
                button = "btns-" + gs_selectedItem;
            }
            llSetLinkPrimitiveParamsFast(gi_linkDesc, [PRIM_TEXTURE, gi_frontFace, button, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 1.0>, 1.0]);
        }
        else if (link == gi_linkApply && gs_selectedItem != "")
        {
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
}


state rezz
{
    state_entry()
    {
        llSetLinkPrimitiveParamsFast(gi_linkApply, [PRIM_TEXTURE, gi_frontFace, "sf-hud-buttons", <0.250, 0.128, 0.0>, <0.125, 0.4, 0.0>, 0.0, PRIM_COLOR, gi_frontFace, <1.0, 1.0, 0.0>, 1.0]);
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
            integer iVersion = llList2Integer(cmd,3);
            if(iVersion != VERSION)
            {
                string repstr = itemsToReplace(llList2String(cmd,4), llList2Key(cmd, 2));
                if (repstr != "")
                {
                    llSay(0, "Preparing rezzed item.");
                    osMessageObject(llList2Key(cmd, 2), "DO-UPDATE|"+PASSWORD+"|"+(string)llGetKey()+"|"+repstr);
                    llSetTimerEvent(20.0);
                    return;
                }
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
            state ready;
        }
    }
}
