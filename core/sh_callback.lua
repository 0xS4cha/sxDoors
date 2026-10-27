local isServer = IsDuplicityVersion();
local currentRequestId = 0;
local handlers = {};
local resourceName = GetCurrentResourceName();
local REQUEST_EVENT = resourceName .. ":callback:request";
local RESPONSE_EVENT = resourceName .. ":callback:response";
local pendings = {};

local function triggerNet(eventName, source, ...)
    if (isServer) then
        TriggerClientEvent(eventName, source, ...);
    else
        TriggerServerEvent(eventName, ...);
    end
end

local function isFunction(v)
    return type(v) == "function"
            or type(v) == "table" and rawget(v, "__cfx_functionReference");
end

local function createProxyHandler(eventName, handlerFn)
    return function(source, ...)
        if (isServer) then
            return handlerFn(source, ...);
        end
        return handlerFn(...);
    end;
end

local function createTimeout(requestId)
    SetTimeout(15000, function()
        if (pendings[requestId]) then
            pendings[requestId].promise:resolve(nil);
            pendings[requestId] = nil;
        end
    end);
end

local function register(eventName, handlerFn)
    assert(type(eventName) == "string", ("Invalid argument at index #1, expected string, got '%s'"):format(type(eventName)));
    assert(isFunction(handlerFn), ("Invalid argument at index #2, expected function, got '%s'"):format(type(handlerFn)));
    assert(not handlers[eventName], ("Attempt to register a callback that already exists: '%s'"):format(eventName));
    handlers[eventName] = createProxyHandler(eventName, handlerFn);
end

local function trigger(eventName, source, ...)
    assert(type(eventName) == "string", ("Invalid argument at index #1, expected string, got '%s'"):format(type(eventName)));
    assert((isServer and type(source) == "number") or true, ("Invalid argument at index #2, expected number, got '%s'"):format(type(source)));
    if (currentRequestId >= 65535) then
        currentRequestId = 0;
    end
    currentRequestId = currentRequestId + 1;
    local p = promise.new();
    pendings[currentRequestId] = {
        source = source,
        promise = p,
        eventName = eventName,
    };
    createTimeout(currentRequestId);
    triggerNet(REQUEST_EVENT, source, eventName, currentRequestId, ...);
    local resolved = Citizen.Await(p);
    if resolved == nil then
        return nil;
    end
    return table.unpack(resolved);
end

RegisterNetEvent(REQUEST_EVENT, function(eventName, requestId, ...)
    local src = source;
    if (handlers[eventName]) then
        local result = { handlers[eventName](src, ...) }
        triggerNet(RESPONSE_EVENT, src, requestId, table.unpack(result));
        return;
    end
end);

RegisterNetEvent(RESPONSE_EVENT, function(requestId, ...)
    local src = source;
    if (type(pendings[requestId]) == "table") then
        if (pendings[requestId].promise) then
            if (isServer and pendings[requestId].source ~= src) then
                return;
            end
            pendings[requestId].promise:resolve({...});
            pendings[requestId] = nil;
        end
    end
end);

if (isServer) then

    function RegisterServerCallback(eventName, handlerFn)
        return register(eventName, handlerFn);
    end

    function TriggerClientCallback(source, eventName, ...)
        return trigger(eventName, source, ...);
    end

else

    function RegisterClientCallback(eventName, handlerFn)
        return register(eventName, handlerFn);
    end

    function TriggerServerCallback(eventName, ...)
        return trigger(eventName, nil, ...);
    end

end
