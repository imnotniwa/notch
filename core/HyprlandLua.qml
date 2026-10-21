pragma Singleton
import QtQuick
import ".."

Item {
    id: root

    function focusWorkspace(wsId) {
        Config.run("hyprctl dispatch 'hl.dsp.focus({workspace=\"" + wsId + "\"})'");
    }

    function cycleWorkspace(forward) {
        let dir = forward ? "e+1" : "e-1";
        Config.run("hyprctl dispatch 'hl.dsp.focus({workspace=\"" + dir + "\"})'");
    }

    function focusWindow(addr) {
        if (!addr) return;
        Config.run("hyprctl dispatch '(function() for _, w in ipairs(hl.get_windows()) do if string.lower(tostring(w.address)) == string.lower(\"" + addr + "\") then return hl.dsp.focus({window = w}) end end end)()'");
    }

    function fullscreenWindow(addr) {
        if (!addr) {
            Config.run("hyprctl dispatch 'hl.dsp.window.fullscreen({})'");
            return;
        }
        Config.run("hyprctl dispatch '(function() for _, w in ipairs(hl.get_windows()) do if string.lower(tostring(w.address)) == string.lower(\"" + addr + "\") then return hl.dsp.window.fullscreen({window = w}) end end end)()'");
    }

    function closeWindow(addr) {
        if (!addr) return;
        Config.run("hyprctl dispatch '(function() for _, w in ipairs(hl.get_windows()) do if string.lower(tostring(w.address)) == string.lower(\"" + addr + "\") then return hl.dsp.window.close({window = w}) end end end)()'");
    }

    function lock() {
        Config.run("hyprlock");
    }

    function toggleSunset() {
        Config.run("pkill -USR1 hyprsunset || hyprsunset");
    }

    function exit() {
        Config.run("hyprctl dispatch 'hl.dsp.exit()'");
    }

    function poweroff() {
        Config.run("systemctl poweroff");
    }

    function reboot() {
        Config.run("systemctl reboot");
    }
}
