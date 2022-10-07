local mime_tbl = {
	['.bmp'] = 'image/x-ms-bmp',
	['.pl'] = 'application/x-perl',
	['.run'] = 'application/x-makeself',
	['.svg'] = 'image/svg+xml',
	['.svgz'] = 'image/svg+xml',
	['.prc'] = 'application/x-pilot',
	['.pdb'] = 'application/x-pilot',
	['.webp'] = 'image/webp',
	['.rar'] = 'application/x-rar-compressed',
	['.woff'] = 'application/font-woff',
	['.rpm'] = 'application/x-redhat-package-manager',
	['.jar'] = 'application/java-archive',
	['.war'] = 'application/java-archive',
	['.sea'] = 'application/x-sea',
	['.7z'] = 'application/x-7z-compressed',
	['.mov'] = 'video/quicktime',
	['.swf'] = 'application/x-shockwave-flash',
	['.bin'] = 'application/octet-stream',
	['.webm'] = 'video/webm',
	['.sit'] = 'application/x-stuffit',
	['.dll'] = 'application/octet-stream',
	['.flv'] = 'video/x-flv',
	['.tcl'] = 'application/x-tcl',
	['.tk'] = 'application/x-tcl',
	['.shtml'] = 'text/html',
	['.pptx'] = 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
	['.m4v'] = 'video/x-m4v',
	['.pdf'] = 'application/pdf',
	['.der'] = 'application/x-x509-ca-cert',
	['.pem'] = 'application/x-x509-ca-cert',
	['.crt'] = 'application/x-x509-ca-cert',
	['.midi'] = 'audio/midi',
	['.ps'] = 'application/postscript',
	['.eps'] = 'application/postscript',
	['.ai'] = 'application/postscript',
	['.gif'] = 'image/gif',
	['.asx'] = 'video/x-ms-asf',
	['.mp3'] = 'audio/mpeg',
	['.rtf'] = 'application/rtf',
	['.jpeg'] = 'image/jpeg',
	['.jpg'] = 'image/jpeg',
	['.ogg'] = 'audio/ogg',
	['.m3u8'] = 'application/vnd.apple.mpegurl',
	['.xspf'] = 'application/xspf+xml',
	['.js'] = 'application/javascript',
	['.m4a'] = 'audio/x-m4a',
	['.xls'] = 'application/vnd.ms-excel',
	['.atom'] = 'application/atom+xml',
	['.ra'] = 'audio/x-realaudio',
	['.eot'] = 'application/vnd.ms-fontobject',
	['.rss'] = 'application/rss+xml',
	['.3gpp'] = 'video/3gpp',
	['.deb'] = 'application/octet-stream',
	['.ppt'] = 'application/vnd.ms-powerpoint',
	['.mml'] = 'text/mathml',
	['.dmg'] = 'application/octet-stream',
	['.ts'] = 'video/mp2t',
	['.wmlc'] = 'application/vnd.wap.wmlc',
	['.avi'] = 'video/x-msvideo',
	['.txt'] = 'text/plain',
	['.img'] = 'application/octet-stream',
	['.mp4'] = 'video/mp4',
	['.kml'] = 'application/vnd.google-earth.kml+xml',
	['.wmv'] = 'video/x-ms-wmv',
	['.jad'] = 'text/vnd.sun.j2me.app-descriptor',
	['.msp'] = 'application/octet-stream',
	['.msm'] = 'application/octet-stream',
	['.kmz'] = 'application/vnd.google-earth.kmz',
	['.asf'] = 'video/x-ms-asf',
	['.wml'] = 'text/vnd.wap.wml',
	['.mng'] = 'video/x-mng',
	['.docx'] = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
	['.mpg'] = 'video/mpeg',
	['.mpeg'] = 'video/mpeg',
	['.htc'] = 'text/x-component',
	['.3gp'] = 'video/3gpp',
	['.cco'] = 'application/x-cocoa',
	['.kar'] = 'audio/midi',
	['.mid'] = 'audio/midi',
	['.png'] = 'image/png',
	['.xlsx'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
	['.jardiff'] = 'application/x-java-archive-diff',
	['.msi'] = 'application/octet-stream',
	['.iso'] = 'application/octet-stream',
	['.tif'] = 'image/tiff',
	['.tiff'] = 'image/tiff',
	['.jnlp'] = 'application/x-java-jnlp-file',
	['.exe'] = 'application/octet-stream',
	['.zip'] = 'application/zip',
	['.xhtml'] = 'application/xhtml+xml',
	['.wbmp'] = 'image/vnd.wap.wbmp',
	['.xpi'] = 'application/x-xpinstall',
	['.json'] = 'application/json',
	['.xml'] = 'text/xml',
	['.doc'] = 'application/msword',
	['.ico'] = 'image/x-icon',
	['.css'] = 'text/css',
	['.htm'] = 'text/html',
	['.html'] = 'text/html',
	['.hqx'] = 'application/mac-binhex40',
	['.jng'] = 'image/x-jng',
	['.pm'] = 'application/x-perl',
	['.ear'] = 'application/java-archive',
}
local len_tbl = {
	3,
	4,
	5,
	6,
	8,
}
local function getPathMIME(path)
    if not path or path:len() <= 0 then
        return
    end
    local plen = path:len()
    for _, klen in ipairs(len_tbl) do
        if plen <= klen then
            break
        end
        local fsuffix = path:sub(plen - klen + 1):lower()
        local mime = mime_tbl[fsuffix]
        if mime then
            return fsuffix, mime
        end
    end
end
local function appendSuffixMIME(fsuffix, mime)
    if fsuffix and mime then
        mime_tbl[fsuffix] = mime
    end
end
return {
    getPathMIME = getPathMIME,
    appendSuffixMIME = appendSuffixMIME
}
