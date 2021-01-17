var ws = new WebSocket('ws://localhost:25500','protocol');
var opt = new URLSearchParams(location.search);
var cmd = opt.get('cmd');
var name = opt.get('name')
document.title = name;
document.querySelector("link[rel~='icon']").href = `/icon/${cmd}.png`;
command(cmd)
function command(cmd) {
    if (cmd === 'terminal') {
        chrome.windows.create({url: '/html/crosh.html'});
        ws.onopen = function() {
            self.close()
        }
    } else {
        ws.onopen = function() {
            ws.send(cmd);
            self.close()
        }
    }
}
