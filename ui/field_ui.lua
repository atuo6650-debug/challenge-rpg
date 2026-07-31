-- ui/field_ui.lua: フィールド・ダンジョン探索中のHUD、フィールドメニューの描画と入力処理を担当する責務。
local unitBuilder = require("unit.builder")

local M = {}

local menuOpen = false
local selected = 1
local actions = {}

local labels = {
    vitality = "生命力",
    strength = "腕力",
    magic = "魔力",
    focus = "集中力",
    spirit = "精神力"
}

function M.configure(menuActions)
    actions = menuActions or {}
    selected = 1
end

function M.isMenuOpen()
    return menuOpen
end

function M.open()
    menuOpen = true
    selected = 1
end

function M.close()
    menuOpen = false
end

function M.toggle()
    if menuOpen then M.close() else M.open() end
end

function M.keypressed(key)
    if not menuOpen then return false end

    if key == "escape" or key == "m" then
        M.close()
        return true
    end

    if key == "up" or key == "w" then
        selected = selected - 1
        if selected < 1 then selected = #actions end
        return true
    end

    if key == "down" or key == "s" then
        selected = selected + 1
        if selected > #actions then selected = 1 end
        return true
    end

    if key == "return" or key == "kpenter" or key == "space" then
        local action = actions[selected]
        if action and action.execute then
            M.close()
            action.execute()
        end
        return true
    end

    return true
end

local function printLine(text, x, y)
    love.graphics.print(text, x, y)
    return y + 16
end

function M.draw(unit)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("M/Esc: フィールドメニュー", 10, 10)

    if not menuOpen then return end

    local x, y, w, h = 40, 40, 330, 350
    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, w, h)

    local cy = y + 16
    cy = printLine("フィールドメニュー", x + 16, cy)
    cy = cy + 6

    for i, action in ipairs(actions) do
        local prefix = (i == selected) and "> " or "  "
        cy = printLine(prefix .. action.label, x + 16, cy)
    end

    cy = cy + 12
    if unit then
        cy = printLine("キャラパラメーター", x + 16, cy)
        for _, key in ipairs(unitBuilder.baseStatKeys()) do
            cy = printLine(string.format("%s: %d", labels[key], unit[key] or 0), x + 24, cy)
        end
        cy = printLine(string.format("HP: %d/%d", math.floor(unit.hp or 0), unit.maxhp or 0), x + 24, cy)
        cy = printLine(string.format("物理攻撃: %d", unit.physical_atk or 0), x + 24, cy)
        cy = printLine(string.format("魔法攻撃: %d", unit.magic_atk or 0), x + 24, cy)
        cy = printLine(string.format("物理防御: %d", unit.physical_def or 0), x + 24, cy)
        printLine(string.format("魔法防御: %d", unit.magic_def or 0), x + 24, cy)
    end
end

return M
