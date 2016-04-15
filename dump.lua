local dump = {}

dump.dump = function(path, tensor)
    if not tensor:isContiguous() then
        error('tensor must be contiguous')
    end
    
    local s
    if tensor:type() == 'torch.FloatTensor' then
        s = torch.FloatStorage(path .. '.data', true, tensor:storage():size())
    elseif tensor:type() == 'torch.LongTensor' then
        s = torch.LongStorage(path .. '.data', true, tensor:storage():size())
    else
        error('unsupported tensor type: ' .. tensor:type())
    end
    
    s:copy(tensor:storage())
    s = nil
    collectgarbage()
    
    torch.save(path .. '.meta', {
        version = 1,
        type = tensor:type(),
        size = tensor:size()
    }, 'ascii')
end

dump.open = function(path)
    local meta = torch.load(path .. '.meta', 'ascii')

    if meta.version ~= 1 then
        error('unsupported version: ' .. meta.v)
    end
    
    local s
    if meta.type == 'torch.FloatTensor' then
        s = torch.FloatTensor(torch.FloatStorage(path .. '.data'))
    elseif meta.type == 'torch.LongTensor' then
        s = torch.LongTensor(torch.LongStorage(path .. '.data'))
    else
        error('unsupported tensor type: ' .. meta.type)        
    end
    
    return s:resize(meta.size)
end

return dump
