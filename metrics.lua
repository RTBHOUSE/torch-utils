local metrics = {}

metrics.Log = {}

metrics.Log.__index = metrics.Log

setmetatable(metrics.Log, {
    __call = function(self, path)
        local log = {
            file = assert(io.open(path, "w")),
            cols = {},
            idx = {},
            row = {},
            c = 0
        }
        setmetatable(log, self)
        return log
    end
})

local getOrInit = function(self, k, t)
    if not self.idx[k] then
        self.idx[k] = #self.cols + 1
        self.cols[#self.cols + 1] = k
    end
    
    local m = self.row[self.idx[k]]
    
    if not m or m.t ~= t then
        m = { t = t }
        self.row[self.idx[k]] = m
    end
    
    return m
end

function metrics.Log.set(self, k, v)
    local m = getOrInit(self, k, 'set')
    m.v = v
end

function metrics.Log.sum(self, k, v)
    local m = getOrInit(self, k, 'sum')
    m.v = (m.v or 0) + v
end

function metrics.Log.mean(self, k, v)
    local m = getOrInit(self, k, 'mean')
    m.v = (m.v or 0) + v
    m.c = (m.c or 0) + 1
end

function metrics.Log.commit(self)
    if self.c == 0 then
        self.file:write(table.concat(self.cols, ',') .. "\n")
    end
    
    for i = 1, #self.cols do
        local m = self.row[i]
        if not m then
            m = ''
        elseif m.t == 'set' then
            m = m.v
        elseif m.t == 'sum' then
            m = m.v
        elseif m.t == 'mean' then
            m = m.v / m.c
        end
        self.row[i] = m
    end
    
    self.file:write(table.concat(self.row, ',') .. "\n")
    self.file:flush()
    
    self.c = self.c + 1
    self.row = {}    
end

function metrics.Log.close(self)
    self.file:close()
end

return metrics
