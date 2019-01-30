//### storage-share.lsl
/*
This script makes it possible to link storages together and share the levels, it is an add-on to storage.lsl
It uses HTTP server and requests, so it also works on two totally different sims of grids that do not even need hypergrid.
(also chatting is possible)
*/

integer chan(key u)
{
    //different channel from typical farm scripts (they have -393)
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) ) - 392;
}
//Log
list log = [];
//pings
integer pingTime = 900;
list lastPing  = [];
integer pingTs;
integer ownPing;
//listens and menus
integer listener;
//for connecting/sharing storage
string ourURL = "";
integer isFirst;
list network = [];
string statusstring = "";
//tmp
string status;
integer connectStage = 0;
key tmpkey;


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    llResetTime();
}

checkListen(integer force)
{
    if (llGetTime() > 300 || force)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

checkPings()
{
    integer curtime = llGetUnixTime();
    if (curtime > (pingTs + pingTime))
    {
        pingTs = curtime;
        if (ourURL != "")
        {
            //check own storage and reset if not available
            if (ownPing < (curtime - (3 * pingTime)))
            {
                string message = "Lost own URL (maybe cause of region restart), connecting again.";
                llSay(0, message);
                log += [message];
                llReleaseURL(ourURL);
                llResetScript();
            }
            llHTTPRequest(ourURL + "?ping", [HTTP_METHOD, "POST"], "");
        }
        if (network != [] && connectStage)
        {
            //check all other connected storages if still online
            integer leng = llGetListLength(lastPing);
            integer change = FALSE;
            while (leng--)
            {
                if (llList2Integer(lastPing, leng) < (curtime - (4 * pingTime)))
                {
                    change = TRUE;
                    log += ["Lost connection to " + llList2String(network, leng)];
                    lastPing = llDeleteSubList(lastPing, leng, leng);
                    network = llDeleteSubList(network, leng, leng);
                }
            }
            if (change)
            {
                saveConfig();
            }
            sendBroadcast(llGetKey(), "ping");
        }
    }
}

disconnectNetwork()
{
    network = [];
    lastPing = [];
    llReleaseURL(ourURL);
    connectStage = 0;
    ourURL = "";
    if (llGetInventoryType("storagenc") == INVENTORY_NOTECARD && (!isFirst || llGetListLength(network) != 1))
    {
        llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
        llRemoveInventory("storagenc");
    }
    if (!isFirst)
    {
        if (llGetInventoryType("storagenc-bc") == INVENTORY_NOTECARD)
        {
            string nc = osGetNotecard("storagenc-bc");
            llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
            osMakeNotecard("storagenc", nc);
        }
    }
    if (llGetInventoryType("config-bc") == INVENTORY_NOTECARD)
    {
        if (llGetInventoryType("config") == INVENTORY_NOTECARD)
        {
            llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
            llRemoveInventory("config");
        }
        string nc = osGetNotecard("config-bc");
        llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
        osMakeNotecard("config", nc);
    }
    if (llGetInventoryType("networknc") == INVENTORY_NOTECARD)
    {
        llRemoveInventory("networknc");
    }
    llMessageLinked(LINK_SET, 84, "RELOAD", NULL_KEY);
}

loadConfig()
{ 
    if (ourURL == "" && llGetInventoryType("networknc") == INVENTORY_NOTECARD)
    {
        network = llParseString2List(osGetNotecard("networknc"), ["\n"], []);
        lastPing = [];
        integer len = llGetListLength(network);
        integer curtime = llGetUnixTime();
        while (len--)
        {
            lastPing += [curtime];
        }
    }
}

saveConfig()
{
    if (llGetInventoryType("networknc") != INVENTORY_NONE)
    {
        llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
        llRemoveInventory("networknc");
    }
    llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
    osMakeNotecard("networknc", llDumpList2String(network, "\n"));
}

sendBroadcast(key agent, string command)
{
    //TODO make this a connection queue that is handled via timer
    //llSay(0, "Send Broadcast " + command + " with name " + name);
    string name = llKey2Name(agent);
    command = "?" + llEscapeURL(command);
    list options = [HTTP_METHOD, "POST"];
    string body = "URL=" + ourURL + "\nAGENT=" + name;
    string url;
    integer length = llGetListLength(network);
    while (length--)
    {
        url = llList2String(network, length);
        if (url != "")
        {
            llHTTPRequest(url + command, options, body);
        }
    }
}


default 
{ 
    listen(integer c, string nm, key id, string m)
    {
        if (m == "Get URI")
        {
            if (ourURL != "")
            {
                llSay(0, "Our url is: " + ourURL + "\nCopy and Paste it into another SatyrFarm Storage to connect them.");
            }
            else
            {
                llRequestURL();
            }
        }
        else if (m == "Log")
        {
            integer len = llGetListLength(log);
            if (len > 140)
            {
                log = llList2List(log, -100, -1);
                len = 100;
            }
            integer i = 0;
            while (i < len)
            {
                llSay(0, llList2String(log, i));
                ++i;
            }
        }
        else if (m == "Say")
        {
            status = "say";
            llTextBox(id, "Type your message", chan(llGetKey()));
            return;
        }
        else if (m == "HELP")
        {
            if (llGetInventoryType("share-help") == INVENTORY_NOTECARD)
            {
                llGiveInventory(id, "share-help");
            }
        }
        else if (m == "Disconnect")
        {
            if (id == llGetOwner())
            {
                llSay(0, "Storage Rack is no longer connected.");
                //if just one, tell the other to disconnect too
                if (llGetListLength(network) == 1)
                {
                    sendBroadcast(id, "disconnect");
                }
                disconnectNetwork();
            }
        }
        else if (m == "Connect to")
        {
            if (id == llGetOwner())
            {
                status = "connect";
                llTextBox(id, "Enter URI of another storage to connect to.\nATTENTION: Connecting this storage to other storages will make you lose whats currently inside.", chan(llGetKey()));
                return;
            }
        }
        else if (status == "connect")
        {
            status = "";
            m = llStringTrim(m, STRING_TRIM);
            if (m == ourURL)
            {
                llSay(0, "Can not connect to myself :)\nEnter this URI on another storage that you want to connect to.");
                return;
            }
            if (llSubStringIndex(m, "http") || llGetSubString(m, -1, -1) != "/")
            {
                llSay(0, "No valid URI :(");
                return;
            }
            network = [m];
            lastPing = [llGetUnixTime()];
            state connect;
        }
        else if (status == "say")
        {
            status = "";
            sendBroadcast(id, "say," + m);
            string message = llKey2Name(id) + " said from this storage:\n" + m;
            llSay(0, message);
            log += [message];
        }
        checkListen(TRUE);
    }
    
    timer()
    {
        checkPings();
        checkListen(FALSE);
        llSetTimerEvent(60);
    }

    state_entry()
    {
        //on state_entry all listeners are cleared
        listener = -1;
        llMessageLinked(LINK_SET, 83, "ADD_MENU_OPTION|Share", NULL_KEY);
        loadConfig();
        if (network != [] && !connectStage)
        {
            state connect;
        }
        llSetTimerEvent(1);
    } 

    changed(integer change)
    {
        if(change & CHANGED_REGION_RESTART)
        {
            llResetScript();
        }
    }

    on_rez(integer num)
    {
        llResetScript();
    }

    link_message(integer sender, integer val, string m, key id)
    {
        if (val < 90)
        {
            return;
        }
        if (m == "RESET") 
        {
            llMessageLinked(LINK_SET, 83, "ADD_MENU_OPTION|Share", NULL_KEY);
            return;
        }
        else if (m == "HARDRESET")
        {
            llReleaseURL(ourURL);
            llRemoveInventory("networknc");
            llResetScript();
            return;
        }
        else if (m == "MENU_OPTION|Share")
        {
            list buttons = ["HELP", " ", "CLOSE"];
            if (!connectStage)
            {
                if (id == llGetOwner())
                {
                    buttons += ["Connect to", "Get URI"];
                }
                else
                {
                    llSay(0, "Just the Owner of this rack can connect it to other racks");
                    return;
                }
            }
            else
            {
                buttons += ["Log", "Say"];
                if (id == llGetOwner())
                {
                    buttons += ["Disconnect", "Get URI"];
                }
            }
            startListen();
            string message = "Share your storage with others.";
            integer num = llGetListLength(network);
            if (num > 0)
            {
                message += "Currently " + (string)num + " storages connected";
            }
            llDialog(id, message, buttons, chan(llGetKey()));
            return;
        }
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok, 0);
        if (cmd == "STORESTATUS")
        {
            statusstring = llDumpList2String(llList2List(tok, 2, -1), ";");
            return;
        }
        if (!connectStage || network == [])
        {
            return;
        }
        if (cmd == "GOTLEVEL")
        {
            string product = llList2String(tok, 1);
            string level = llList2String(tok, 2);
            log += ["This rack set level from " + product + " to " + level];
            sendBroadcast(llGetKey(), "setlevel," + product + "," + level);
        }
        else if (cmd == "REZZEDPRODUCT")
        {
            key agent = llList2Key(tok, 1);
            string product = llList2String(tok, 2);
            log += [llKey2Name(agent) + " took one " + product + " from this storage."];
            sendBroadcast(agent, "add," + product + ",-1");
        }
        else if (cmd == "GOTPRODUCT")
        {
            key agent = llList2Key(tok, 1);
            string product = llList2String(tok, 2);
            log += [llKey2Name(agent) + " added one " + product + " into this storage."];
            sendBroadcast(agent, "add," + product + ",1");
        }
    }
    
    http_request(key id, string methode, string body)
    {
        integer responseStatus = 400;
        string responseBody = "Unsupported Methode";
        if (methode == URL_REQUEST_GRANTED)
        {
            if (llSubStringIndex(body, "127.0.0.1") != -1)
            {
                llSay(0, "This Region does not have a valid ExternalHostNameForLSL set in the OpenSim.ini, can't connect Storage Rack :(");
                llReleaseURL(body);
            }
            else
            {
                ourURL = body;
                ownPing = llGetUnixTime();
                llSay(0, "Got url: " + body + "\nCopy and Paste it into another SatyrFarm Storage to connect them.");
            }
            responseStatus = 200;
            responseBody = "ACK";
        }
        else if (methode == URL_REQUEST_DENIED)
        {
            llSay(0, "Region does not allow us to get URL with message:\n" + body);
            responseStatus = 200;
            responseBody = "ACK";
        }
        else
        {
            string get = llGetHTTPHeader(id,"x-query-string");
            //workaround for opensim 0.8 Bug
            if (llGetSubString(get, 0, 0) == "=") get = llGetSubString(get, 1, -1);

            string requrl = llGetHTTPHeader(id, "x-script-url");
            if (requrl != ourURL)
            {
                llReleaseURL(requrl);
                responseStatus = 404;
                responseBody = "Not Found";
            }
            else if (methode == "POST")
            {
                string uri;
                string agent;
                string region = llGetHTTPHeader(id,"x-secondlife-region");
                //parse parameters from body
                list bodyl = llParseString2List(body, ["\n"], []);
                integer len = llGetListLength(bodyl);
                while (len--)
                {
                    string param = llList2String(bodyl, len);
                    integer index = llSubStringIndex(param, "=");
                    if (index != -1)
                    {
                        string skey = llGetSubString(param, 0, index - 1);
                        string svalue = llGetSubString(param, index + 1, -1);
                        if (skey == "URL") uri = svalue;
                        else if (skey == "AGENT") agent = svalue;
                        else if (skey == "REGION") region = svalue;
                    }
                }

                if (get == "ping")
                {
                    responseStatus = 200;
                    responseBody = ourURL;
                    if (llSubStringIndex(uri, "http") == 0 && uri != ourURL && llListFindList(network, [uri]) == -1)
                    {
                        string message = "New storage rack from region " + region + " connected through ping.";
                        log += [message];
                        llSay(0, message);
                        network += [uri];
                        lastPing += [llGetUnixTime()];
                    }
                }
                else if (get == "connect")
                {
                    if (llListFindList(network, [uri]) != -1)
                    {
                        responseBody = "Already added";
                        responseStatus = 200;
                    }
                    else
                    {
                        if (!connectStage)
                        {
                            connectStage = 3;
                            isFirst = TRUE;
                        }
                        network += [uri];
                        lastPing += [llGetUnixTime()];
                        saveConfig();
                        string message = "New storage rack from region " + region + " connected";
                        llSay(0, message);
                        log += [message];
                        responseBody = "Added you.";
                        responseStatus = 200;
                    }
                }
                else if (get == "disconnect")
                {
                    disconnectNetwork();
                }
                else if (!llSubStringIndex(get, "add"))
                {
                    list args = llParseString2List(llUnescapeURL(get), [","], []);
                    string product = llList2String(args, 1);
                    integer amount = llList2Integer(args, 2);
                    string message = agent;
                    if (amount == 1) message += " added one ";
                    else if (amount == -1) message += " removed one ";
                    else message += " added " + (string)amount + " ";
                    message += product + " from storage in Region " + region;
                    llSay(0, message);
                    log += [message];
                    llMessageLinked(LINK_SET, 84, "ADDPRODUCTNUM|" + product + "|" + (string)amount, NULL_KEY);
                    responseBody = "OK";
                    responseStatus = 200;
                }
                else if (!llSubStringIndex(get, "setlevel"))
                {
                    list args = llParseString2List(llUnescapeURL(get), [","], []);
                    string product = llList2String(args, 1);
                    integer amount = llList2Integer(args, 2);
                    string message = agent + " in region " + region + " set level of " + product + " to " + (string)amount;
                    llSay(0, message);
                    log += [message];
                    llMessageLinked(LINK_SET, 84, "SETLEVEL|" + product + "|" + (string)amount, NULL_KEY);
                    responseBody = "OK";
                    responseStatus = 200;
                }
                else if (!llSubStringIndex(get, "say"))
                {
                    list args = llParseString2List(llUnescapeURL(get), [","], []);
                    string message = agent + " in region " + region + " said:\n" + llList2String(args, 1);
                    llSay(0, message);
                    log += [message];
                }
            }
            else if (methode == "GET")
            {
                if (get == "ping")
                {
                    responseStatus = 200;
                    responseBody = "pong";
                }
                else if (get == "network")
                {
                    responseStatus = 200;
                    responseBody = llDumpList2String(network, "\n");
                    if (responseBody == "")
                    {
                        responseBody = "empty";
                    }
                }
                else if (get == "config")
                {
                    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
                    {
                        responseBody = osGetNotecard("config");
                        if (responseBody == "")
                        {
                            responseBody = "empty";
                        }
                        responseStatus = 200;
                    }
                    else
                    {
                        responseBody = "";
                        responseStatus = 200;
                    }
                }
                else if (get == "levels")
                {
                    responseBody = statusstring;
                    if (statusstring != "")
                    {
                        responseStatus = 200;
                    }
                    else
                    {
                        responseStatus = 522;
                    }
                }
            }
        }
        llHTTPResponse(id, responseStatus, responseBody);
    }

    http_response(key id, integer httpStatus, list metaData, string body)
    {
        //llOwnerSay("Got response " + (string)httpStatus + " : " + body + "\n" + llDumpList2String(metaData, ",") + "\n" + requrl);
        if (!llSubStringIndex(body, "http"))
        {
            //ping response of url
            integer found = llListFindList(network, [body]);
            if (found != -1)
            {
                lastPing = llListReplaceList(lastPing, [llGetUnixTime()], found, found);
            }
            else if (body == ourURL)
            {
                ownPing = llGetUnixTime();
            }
        }
    }
}


state connect
{
    state_entry()
    {
        //give it some time
        //let it be able to do HARDRESET
        llSetTimerEvent(5.);
    }

    timer()
    {
        llSetTimerEvent(0.);
        if (ourURL != "" )
        {
            llReleaseURL(ourURL);
            ourURL = "";
        }
        connectStage = 0;
        llSay(0, "Connecting to network....");
        llRequestURL();
    }

    link_message(integer sender, integer val, string m, key id)
    {
        if (m == "HARDRESET")
        {
            network = [];
            llReleaseURL(ourURL);
            llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
            llRemoveInventory("networknc");
            llResetScript();
            return;
        }
    }

    http_request(key id, string methode, string body)
    {
        if (methode == URL_REQUEST_GRANTED)
        {
            if (llSubStringIndex(body, "127.0.0.1") != -1)
            {
                llSay(0, "This Region does not have a valid ExternalHostNameForLSL set in the OpenSim.ini, can't connect Storage Rack :(");
                llHTTPResponse(id, 500, "failed");
                llReleaseURL(body);
                return;
            }
            ourURL = body;
            ownPing = llGetUnixTime();
            llHTTPResponse(id, 200, "success");
            connectStage = 0;
            tmpkey = llHTTPRequest(llList2String(network, 0) + "?network", [HTTP_METHOD, "GET"], "");
        }
        else if (methode == URL_REQUEST_DENIED)
        {
            llHTTPResponse(id, 500, "failed");
            llSay(0, "Region does not allow us to get URL with message:\n" + body);
        }
    }

    http_response(key id, integer httpStatus, list metaData, string body)
    {
        if (id != tmpkey)
        {
            return;
        }
        tmpkey = NULL_KEY;
        //llOwnerSay("Got response " + (string)httpStatus + " : " + body + "\n" + llDumpList2String(metaData, ","));
        if (httpStatus >= 400 || body == "")
        {
            llSay(0, "Couldn't connect to " + llList2String(network, 0) + " with status: " + (string)httpStatus + "\n" + body);
            network = llDeleteSubList(network, 0, 0);
            lastPing = llDeleteSubList(lastPing, 0, 0);
            connectStage = 0;
            if (network != [])
            {
                llSay(0, "Trying next storage in network...");
                tmpkey = llHTTPRequest(llList2String(network, 0) + "?network", [HTTP_METHOD, "GET"], "");
            }
            else
            {
                llSay(0, "Could not connect to network!");
                saveConfig();
                state default;
            }
        }
        else
        {
            ++connectStage;
            if (connectStage == 1)
            {
                integer curtime = llGetUnixTime();
                if (body != "empty")
                {
                    list nc = llParseString2List(body, ["\n"], []);
                    integer len = llGetListLength(nc);
                    while (len--)
                    {
                        string conurl = llList2String(nc, len);
                        if (llListFindList(network, [conurl]) == -1 && conurl != ourURL)
                        {
                            network += [conurl];
                            lastPing += [curtime];
                        }
                    }
                }
                pingTs = curtime;
                llSay(0, "Network has " + (string)llGetListLength(network) + " connected SatyrFarm storages.");
                tmpkey = llHTTPRequest(llList2String(network, 0) + "?config", [HTTP_METHOD, "GET"], "");
            }
            else if (connectStage == 2)
            {
                if (body == "empty")
                {
                    body = "";
                }
                if (llGetInventoryType("config") == INVENTORY_NOTECARD)
                {
                    if (llGetInventoryType("config-bc") != INVENTORY_NONE)
                    {
                        llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                        llRemoveInventory("config-bc");
                    }
                    string nc = osGetNotecard("config");
                    llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                    osMakeNotecard("config-bc", nc);
                    llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                    llRemoveInventory("config");
                }
                llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                osMakeNotecard("config", body);
                //llSay(0, "Loaded network configuration.");
                tmpkey = llHTTPRequest(llList2String(network, 0) + "?levels", [HTTP_METHOD, "GET"], "");
            }
            else if (connectStage == 3)
            {
                if (llGetInventoryType("storagenc-bc") == INVENTORY_NOTECARD)
                {
                    llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                    llRemoveInventory("storagenc-bc");
                }
                if (llGetInventoryType("storagenc") == INVENTORY_NOTECARD)
                {
                    llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                    string nc = osGetNotecard("storagenc");
                    osMakeNotecard("storagenc-bc", nc);
                }
                llMessageLinked(LINK_SET, 84, "SETSTATUS|" + llDumpList2String(llParseString2List(body, [";"], []), "|"), NULL_KEY);
                llSay(0, "Got Products and Levels from network");
                llSay(0, "Done :)\nThis storage is now connected. It might need about one minute till other storages in the network realize it.");
                isFirst = FALSE;
                log += ["Connected to network..."];
                sendBroadcast(llGetOwner(), "connect");
                saveConfig();
                state default;
            }
        }
    }
}


