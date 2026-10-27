RegisterCommand('adminpanel', function()
    local isAdmin = TriggerServerCallback('sxAdmin:isAdmin')
    if isAdmin then
        SX.UI:Open('admin')
    else
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(GetPhrase('admin_no_permission'))
        EndTextCommandThefeedPostTicker(false, true)
    end
end, false)

RegisterKeyMapping('adminpanel', GetPhrase('keymap_admin_panel'), 'keyboard', '')
