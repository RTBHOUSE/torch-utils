local dashboard = {}

local Plot = require 'itorch.Plot'

local parse = function(datasets, opts)
    local list = {}
    local idx = {}
    
    for _, dataset in ipairs(datasets) do
        local lines = io.lines(dataset.path)
        
        local cols = {}
        
        for col in string.gmatch(lines(), '([^,]+)') do
            table.insert(cols, col)
        end
        
        local n = 1 + (dataset.shift or 0)
        for l in lines do
            local c = 1
            
            for v in string.gmatch(l .. ',', '([^,]*),') do
                local g = cols[c] or ('' .. c)
                local m = dataset.name
                
                local a, b = g:match('([^:]+):(.+)')
                if a and b then
                    g = a
                    m = m .. ':' .. b
                end
                
                local group = idx[g]
                if not group then
                    group = {
                        name = g,
                        list = {},
                        idx = {}
                    }
                    
                    list[#list + 1] = group
                    idx[g] = group
                end
                    
                local group = idx[g]
                
                local metric = group.idx[m]
                if not metric then
                     metric = {
                        name = m,
                        x = {},
                        y = {}
                    }
                    
                    group.list[#group.list + 1] = metric
                    group.idx[m] = metric
                end
                
                if v ~= '' and (not opts.from or n >= opts.from) and (not opts.to or n <= opts.to) then
                    table.insert(metric.x, n)
                    table.insert(metric.y, tonumber(v))
                end
                
                c = c + 1
            end
            n = n + 1
        end
    end
    
    local max = 0
    for k, v in ipairs(list) do
        v.idx = nil
        if opts.cut and opts.cut > 0 then
            for k2,v2 in ipairs(v.list) do
                if max < #v2.x then
                    max = #v2.x
                end
                for i=1,opts.cut do
                    table.remove(v2.x)
                    table.remove(v2.y)
                end
            end
        end
    end
    if opts.cut and max <= opts.cut then
        print("Change cut parameter to not remove all data (should be not greater than " .. max - 2 .. ")!")
    end
    
    return list
end

local plot = function(group, opts)
    local p = Plot()
    
    p:title(group.name)
    p:legend(true)

    local palette = {
        'red', 'green', 'blue', 'purple', 'yellow', 'teal', 
        'maroon', 'lime', 'navy', 'fuchsia', 'olive', 'aqua'}
    
    local c = 0
   
    for k, v in ipairs(group.list) do
        if #v.x > 0 and (not opts.metrics or v.name:match(opts.metrics)) then
            if opts.type == 'circle' then
                p:circle(v.x, v.y, palette[c] or 'black', v.name)
            else
                p:line(v.x, v.y, palette[c] or 'black', v.name)
            end
            c = c + 1
        end
    end
    
    if c > 0 then
        p:draw()
    end
end

dashboard.show = function(opts)
    local groups = parse(opts.datasets, opts)
    
    for k, v in ipairs(groups) do
        if not opts.groups or v.name:match(opts.groups) then
            plot(v, opts)
        end
    end
end

return dashboard
