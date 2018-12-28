//### storage-share.lsl

integer chan(key u)
{
    //different channel from typical farm scripts (they have -393)
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) ) - 392;
}
//Log
list log = [];
//pings
integer pingTime = 60;
list lastPing  = [];
integer pingTs;
//listens and menus
integer listener;
//for connecting/sharing storage
string ourURL = "";
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
    if (curtime > pingTs + pingTime)
    {
        pingTs = curtime;
        integer leng = llGetListLength(lastPing);
        integer change = FALSE;
        while (leng--)
        {
            if (llList2Integer(lastPing, leng) < curtime - 3 * pingTime)
            {
                change = TRUE;
                lastPing = llDeleteSubList(lastPing, leng, leng);
                network = llDeleteSubList(network, leng, leng);
            }
        }
        if (change)
        {
            saveConfig();
        }
        sendBoradcast(llGetKey(), "ping");
    }
}

loadConfig()
{ 
    if (ourURL == "" && llGetInventoryType("networknc") == INVENTORY_NOTECARD)
    {
        list nc = llParseString2List(osGetNotecard("networknc"), ["\n"], []);
        network = llList2List(nc, 1, -1);
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

sendBoradcast(key agent, string command)
{
    //TODO make this a connection queue that is handled via timer
    command = "?" + llEscapeURL(command);
    list options = [HTTP_METHOD, "GET", HTTP_CUSTOM_HEADER, "x-satyrfarm-agent", llKey2Name(agent), HTTP_CUSTOM_HEADER, "x-satyrfarm-uri", ourURL];
    string body = "";
    string url;
    integer length = llGetListLength(network);
    while (length--)
    {
        url = llList2String(network, length);
        //llSay(0, "Send command " + command + " to url " + url);
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
            llReleaseURL(ourURL);
            connectStage = 0;
            ourURL = "";
            llSay(0, "Storage Rack is no longer connected.");
            network = [];
            lastPing = [];
            if (llGetInventoryType("networknc") == INVENTORY_NOTECARD)
            {
                llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                llRemoveInventory("networknc");
            }
            if (llGetInventoryType("storagenc") == INVENTORY_NOTECARD)
            {
                llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                llRemoveInventory("storagenc");
            }
            if (llGetInventoryType("storagenc-bc") == INVENTORY_NOTECARD)
            {
                string nc = osGetNotecard("storagenc-bc");
                llMessageLinked(LINK_SET, 84, "IGNORE_CHANGED", NULL_KEY);
                osMakeNotecard("storagenc", nc);
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
            if (llGetInventoryType("storage") == INVENTORY_SCRIPT)
            {
                llResetOtherScript("storage");
            }
            saveConfig();
        }
        else if (m == "Connect to")
        {
            status = "connect";
            llTextBox(id, "Enter URI of another storage to connect to.\nATTENTION: Connecting this storage to other storages will make you lose whats currently inside.", chan(llGetKey()));
            return;
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
            sendBoradcast(id, "say," + m);
            log += [llKey2Name(id) + " said from this storage:\n" + m];
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
        //give it some time to load inventory items
        llSleep(3.0);
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
            startListen();
            list buttons = ["HELP", " ", "CLOSE", "Get URI"];
            if (!connectStage)
            {
                buttons += ["Connect to"];
            }
            else
            {
                buttons += ["Disconnect", "Log", "Say"];
            }
            llDialog(id, "Share your storage with others.", buttons, chan(llGetKey()));
            return;
        }
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok, 0);
        if (cmd == "STORESTATUS")
        {
            statusstring = llDumpList2String(llList2List(tok, 2, -1), ";");
        }
        else if (cmd == "GOTLEVEL")
        {
            sendBoradcast(llGetKey(), "setlevel," + llList2String(tok, 1) + "," + llList2String(tok, 2));
        }
        else if (cmd == "REZZEDPRODUCT")
        {
            sendBoradcast(llList2Key(tok, 1), "add," + llList2String(tok, 2) + ",-1");
        }
        else if (cmd == "GOTPRODUCT")
        {
            sendBoradcast(llList2Key(tok, 1), "add," + llList2String(tok, 2) + ",1");
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
        else if (methode == "GET")
        {
            string get = llGetHTTPHeader(id,"x-query-string");
            string region = llGetHTTPHeader(id,"x-secondlife-region");
            string agent = llGetHTTPHeader(id, "x-satyrfarm-agent");
            string requrl = llGetHTTPHeader(id, "x-script-url");
            //llOwnerSay("DEBUG: get= " + get + " from owner " + agent + " in region " + region);
            if (requrl != ourURL)
            {
                llReleaseURL(requrl);
                responseStatus = 404;
                responseBody = "Not Found";
            }
            if (get == "ping")
            {
                responseStatus = 200;
                responseBody = ourURL;
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
            else if (get == "connect")
            {
                string uri = llGetHTTPHeader(id, "x-satyrfarm-uri");
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
        llHTTPResponse(id, responseStatus, responseBody);
    }

    http_response(key id, integer httpStatus, list metaData, string body)
    {
        string requrl = llGetHTTPHeader(id, "x-script-url");
        //llOwnerSay("Got response " + (string)httpStatus + " : " + body + "\n" + llDumpList2String(metaData, ",") + "\n" + requrl);
        if (!llSubStringIndex(body, "http"))
        {
            //ping response of url
            integer found = llListFindList(network, [body]);
            if (found != -1)
            {
                lastPing = llListReplaceList(lastPing, [llGetUnixTime()], found, found);
            }
        }
    }
}


state connect
{
    state_entry()
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
            llSay(0, "Couldn't connect to " + llList2String(network, 0));
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
                if (body != "empty")
                {
                    list nc = llParseString2List(body, ["\n"], []);
                    network += llList2List(nc, 1, -1);
                    integer len = llGetListLength(nc);
                    integer curtime = llGetUnixTime();
                    while (len--)
                    {
                        lastPing += [curtime];
                    }
                }
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
                llMessageLinked(LINK_SET, 84, "SETSTATUS|" + llDumpList2String(llParseString2List(body, [";"], []), "|"), NULL_KEY);
                llSay(0, "Got Products and Levels from network");
                llSay(0, "Done :)\nThis storage is now connected. It might need about one minute till other storages in the network realize it.");
                log += ["Connected to network..."];
                sendBoradcast(llGetOwner(), "connect");
                saveConfig();
                state default;
            }
        }
    }
}


