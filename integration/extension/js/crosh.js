var NEWTERM = 'chrome-untrusted://crosh/',
    OLDTERM = 'chrome-extension://nkoccljplnhpfnfiajclkommnmllphnl/html/crosh.html';
chrome.runtime.sendMessage('nkoccljplnhpfnfiajclkommnmllphnl', null, null, (response) => {
    if (chrome.runtime.lastError) {
        var TERM = NEWTERM
    } else {
        var TERM = OLDTERM
    }
};
chrome.tabs.update(TERM)
