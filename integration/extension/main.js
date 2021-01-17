window.onload(function() {
    var opt = new URLSearchParams(location.search);
    var cmd = opt.get('cmd');
    document.title = cmd[0].toUpperCase() + cmd.slice(1);
    document.querySelector("link[rel~='icon']").href = `/icon/${cmd}.png`;
    command(cmd)
});
function command(cmd) {
    if (cmd = 'terminal') {
        chrome.windows.open('/html/crosh.html');
        self.close()
    } else {
        var ws = new WebSocket('ws://localhost:25500','protocol');
        ws.onopen = function() {
            ws.send(cmd);
            self.close()
        }
    }
}
