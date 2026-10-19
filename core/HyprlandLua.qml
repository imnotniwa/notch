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
        Config.run("hyprctl dispatch 'hl.dsp.focus({window=\"address:" + addr + "\"})'");
    }

    function fullscreenWindow() {
        Config.run("hyprctl dispatch 'hl.dsp.window.fullscreen({})'");
    }

    function closeWindow(addr) {
        if (!addr) return;
        Config.run("hyprctl dispatch 'hl.dsp.window.close({address=\"" + addr + "\"})'");
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
