//
//  content.js
//  ShortformBeGoneSafariGuard
//
//  Sites such as YouTube and Facebook move between views without loading a
//  new page: they swap the content in place and rewrite the address bar. No
//  request is made that a filter or content blocker could refuse. This script
//  runs inside those pages, watches the address, and leaves for the site's
//  home page as soon as the address is one of the short-form sections.
//
//  SECTIONS must list the same sections as FilterRules.standardDenyPaths;
//  a unit test checks that it does.
//

const SECTIONS = [
    "youtube.com/shorts",
    "youtube.com/youtubei/v1/reel",
    "instagram.com/reel",
    "instagram.com/explore",
    "facebook.com/reel",
    "facebook.com/watch",
    "snapchat.com/spotlight"
];

function isShortForm(address) {
    const host = address.hostname.toLowerCase();
    const path = address.pathname.toLowerCase();
    return SECTIONS.some((section) => {
        const slash = section.indexOf("/");
        const sectionHost = section.slice(0, slash);
        const sectionPath = section.slice(slash);
        const hostMatches = host === sectionHost || host.endsWith("." + sectionHost);
        return hostMatches && path.startsWith(sectionPath);
    });
}

let leaving = false;

function check() {
    if (leaving || !isShortForm(window.location)) { return; }
    leaving = true;
    // Stop whatever is already playing before the page goes away.
    document.querySelectorAll("video, audio").forEach((media) => {
        try { media.pause(); media.removeAttribute("src"); media.load(); } catch (error) { }
    });
    if (document.documentElement) { document.documentElement.style.visibility = "hidden"; }
    window.stop();
    window.location.replace(window.location.origin + "/");
}

check();
window.addEventListener("popstate", check);
window.addEventListener("hashchange", check);
// In-page navigation rewrites the address without any event this script can
// rely on, so look again several times a second.
setInterval(check, 250);
