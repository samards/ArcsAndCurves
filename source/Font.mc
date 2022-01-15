using Toybox.WatchUi as ui;

class Font {

    var fontcache;
    var fontLRU;
    var fontheight;
    var fontlookups;
    var letterwidths;
    var fontmemorysize;

    var normal;

    function initialize() {

        fontcache = {};
        fontLRU = [];
        fontlookups = getLookupsmiriam();

        var stats = System.getSystemStats();
        var memory = stats.freeMemory;

        // get the unrotated font height
        normal = (fontlookups[0][0] & 0x7fc0000) >> 18;
        fontheight = Graphics.getFontHeight(getFont(normal));

        stats = System.getSystemStats();
        fontmemorysize = memory-stats.freeMemory;
        System.println("Size of font file is " + fontmemorysize); // DEBUG
        letterwidths = ui.loadResource(Rez.JsonData.letterwidths_miriam);
    }

    function freeMemory(f, fc, fLRU) {
        // if we have low memory, evict a font from the cache
        var stats = System.getSystemStats();
        if(fontmemorysize != null && stats.freeMemory < fontmemorysize*4) {
            if(fontLRU.size() > 0) {
                var oldfont = fLRU.get(f);
                System.println("ejecting font " + oldfont + " from cache"); // DEBUG
                fc.remove(oldfont);
                fLRU.remove(oldfont);
            }
        }
    }

    // load a font and cache it, use a LRU to free old fonts if memory low
    function getFont(f) {
        var font = fontcache.get(f);
        if(font == null) {
            freeMemory(f, fontcache, fontLRU);
            System.println("loading font resource " + f); // DEBUG
            font = getFontmiriam(f);
            fontcache.put(f,font);
        }
           
        // update the LRU
        fontLRU.remove(f);
        fontLRU.add(f);

        return(font);
    }

}
