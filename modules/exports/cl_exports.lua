exports("OpenPanel", function(panel)
    SX.UI:Open(panel or 'group')
end)

exports("ClosePanel", function()
    SX.UI:Close()
end)

exports("IsPanelOpen", function()
    return SX.UI:IsOpen()
end)
